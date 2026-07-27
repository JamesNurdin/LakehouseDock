WITH sales_by_time AS (
    SELECT
        ws_sold_time_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_qty
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 1000
    GROUP BY ws_sold_time_sk
)
SELECT
    td.t_hour,
    td.t_shift,
    sbt.total_profit,
    sbt.total_qty
FROM sales_by_time sbt
JOIN time_dim td
    ON sbt.ws_sold_time_sk = td.t_time_sk
WHERE td.t_shift = 'first' AND td.t_hour BETWEEN 6 AND 12

UNION ALL

SELECT
    td.t_hour,
    td.t_shift,
    sbt.total_profit,
    sbt.total_qty
FROM sales_by_time sbt
JOIN time_dim td
    ON sbt.ws_sold_time_sk = td.t_time_sk
WHERE td.t_shift = 'third' AND td.t_hour BETWEEN 18 AND 23

ORDER BY t_hour
LIMIT 100
