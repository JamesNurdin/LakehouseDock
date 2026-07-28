WITH ship_sales AS (
    SELECT
        w.w_country,
        w.w_state,
        SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_dep_count >= 4
    GROUP BY w.w_country, w.w_state
),
bill_sales AS (
    SELECT
        w.w_country,
        w.w_state,
        SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_vehicle_count > 0
    GROUP BY w.w_country, w.w_state
)
SELECT
    country,
    state,
    SUM(profit) AS total_profit
FROM (
    SELECT w_country AS country, w_state AS state, profit FROM ship_sales
    UNION ALL
    SELECT w_country AS country, w_state AS state, profit FROM bill_sales
) u
GROUP BY country, state
HAVING SUM(profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
