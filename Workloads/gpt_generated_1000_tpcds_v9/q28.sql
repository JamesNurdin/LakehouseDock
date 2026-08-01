SELECT
    t.t_shift,
    t.t_meal_time,
    REGEXP_EXTRACT(t.t_time_id, '^([0-9]{2})', 1) AS hour_str,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 500 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    (SELECT SUM(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        JOIN time_dim t2 ON ws2.ws_sold_time_sk = t2.t_time_sk
        WHERE t2.t_shift = t.t_shift
          AND t2.t_meal_time = t.t_meal_time) AS total_sales_shift_meal
FROM time_dim t
LEFT JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
WHERE
    REGEXP_LIKE(t.t_time_id, '^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')
    AND t.t_shift LIKE 'first%'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr_check
        WHERE sr_check.sr_return_time_sk = t.t_time_sk
          AND sr_check.sr_net_loss > 100
    )
GROUP BY
    t.t_shift,
    t.t_meal_time,
    REGEXP_EXTRACT(t.t_time_id, '^([0-9]{2})', 1)
ORDER BY
    total_net_loss DESC,
    t.t_shift
LIMIT 100
