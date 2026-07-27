WITH per_page_hour AS (
    SELECT
        wp.wp_web_page_sk,
        td.t_hour,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_refunded_cash) AS avg_refunded_cash
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour IN (6, 12, 14)
      AND wp.wp_creation_date_sk IN (2450800, 2450807)
      AND wr.wr_return_amt > 100
    GROUP BY wp.wp_web_page_sk, td.t_hour, wp.wp_type
),
type_summary AS (
    SELECT
        wp_type,
        AVG(total_return_amt) AS avg_return_amt,
        SUM(total_return_qty) AS sum_return_qty
    FROM per_page_hour
    GROUP BY wp_type
)
SELECT
    ts.wp_type,
    ts.avg_return_amt,
    ts.sum_return_qty
FROM type_summary ts
WHERE ts.avg_return_amt > (
    SELECT AVG(total_return_amt) FROM per_page_hour
)
ORDER BY ts.avg_return_amt DESC
LIMIT 100
