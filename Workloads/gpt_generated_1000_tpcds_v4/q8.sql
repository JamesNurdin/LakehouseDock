WITH sales_time AS (
    SELECT
        cs.cs_ship_mode_sk,
        td.t_hour,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_ship_mode_sk IN (2, 3, 4)
        AND cs.cs_warehouse_sk = 9
        AND cs.cs_quantity > 1
        AND td.t_hour BETWEEN 8 AND 16
        AND td.t_second > 5
),
agg_by_mode_hour AS (
    SELECT
        cs_ship_mode_sk,
        t_hour,
        SUM(cs_net_paid) AS sum_net_paid,
        SUM(cs_net_profit) AS sum_net_profit,
        COUNT(*) AS cnt_sales
    FROM sales_time
    GROUP BY cs_ship_mode_sk, t_hour
)
SELECT
    cs_ship_mode_sk,
    AVG(sum_net_paid) AS avg_sum_net_paid,
    SUM(cnt_sales) AS total_sales,
    SUM(sum_net_profit) AS total_profit
FROM agg_by_mode_hour
GROUP BY cs_ship_mode_sk
HAVING AVG(sum_net_paid) > 1000
ORDER BY avg_sum_net_paid DESC
LIMIT 100
