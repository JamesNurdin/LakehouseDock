WITH sales_by_time AS (
    SELECT
        td.t_time_sk,
        td.t_shift,
        td.t_sub_shift,
        td.t_meal_time,
        COUNT(*) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        CASE
            WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_profit) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_sub_shift LIKE '%even%'
      AND regexp_like(td.t_meal_time, '^break|^lunch|^dinner$')
      AND substr(td.t_time_id, 1, 2) = 'T0'
    GROUP BY td.t_time_sk, td.t_shift, td.t_sub_shift, td.t_meal_time
    HAVING COUNT(*) > 10
)
SELECT
    sbt.t_shift,
    sbt.t_sub_shift,
    sbt.t_meal_time,
    sbt.total_sales,
    sbt.total_profit,
    sbt.distinct_items,
    sbt.profit_category,
    regexp_extract(td2.t_time_id, '(\\d+)', 1) AS time_id_number,
    sbt.avg_net_paid
FROM sales_by_time sbt
JOIN time_dim td2
    ON sbt.t_time_sk = td2.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws3
    WHERE ws3.ws_sold_time_sk = sbt.t_time_sk
      AND ws3.ws_net_paid_inc_ship > 5000
)
ORDER BY sbt.total_profit DESC
LIMIT 100
