WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        i.inv_quantity_on_hand,
        sr.sr_return_amt,
        sr.sr_net_loss,
        t.t_hour,
        wp.wp_type,
        ws.web_name,
        ws.web_gmt_offset
    FROM date_dim d
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.inv_quantity_on_hand > 0
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.web_gmt_offset = -5.00
)
SELECT
    d_date,
    web_name,
    SUM(sr_return_amt) AS total_return_amt,
    SUM(sr_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY d_date ORDER BY SUM(sr_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(sr_return_amt) > 10000 THEN 'High'
        WHEN SUM(sr_return_amt) > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM base
GROUP BY d_date, web_name
ORDER BY d_date, loss_rank
LIMIT 100
