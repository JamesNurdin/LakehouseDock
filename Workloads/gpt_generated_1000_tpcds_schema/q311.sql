WITH exclusive_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
all_joins AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        d.d_year,
        d.d_date,
        t.t_hour,
        t.t_minute,
        t.t_second,
        s.s_store_id,
        s.s_hours,
        wp.wp_web_page_id,
        wp.wp_char_count
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_current_week = 'N'
      AND d.d_year BETWEEN 1999 AND 2001
      AND t.t_minute IN (3, 12, 16)
      AND t.t_second IN (0, 10, 16)
      AND wp.wp_char_count > 1500
      AND s.s_hours = '8AM-4PM             '
)
SELECT
    a.d_year,
    a.s_store_id,
    a.t_hour,
    COUNT(DISTINCT a.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT a.wr_order_number) AS web_order_cnt,
    SUM(a.cr_return_amount) AS total_catalog_return_amount,
    AVG(a.wr_return_amt) AS avg_web_return_amount,
    SUM(CASE WHEN a.cr_net_loss > 0 THEN a.cr_net_loss ELSE 0 END) AS total_positive_net_loss,
    MIN(a.cr_return_quantity) AS min_return_qty,
    MAX(a.wr_return_quantity) AS max_web_return_qty,
    (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2000) AS max_date_2000
FROM all_joins a
JOIN exclusive_orders eo
  ON a.cr_order_number = eo.cr_order_number
GROUP BY a.d_year, a.s_store_id, a.t_hour
ORDER BY total_catalog_return_amount DESC
LIMIT 100
