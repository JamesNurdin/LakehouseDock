/*
Goal: Compare profitability and order volume by household demographic groups for billing vs. shipping households, applying different filters, and combine the results into a single result set.
*/
WITH bill_sales AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        hd.hd_vehicle_count AS vehicle_cnt,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_wholesale_cost BETWEEN 30 AND 80
      AND hd.hd_vehicle_count >= 0
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
),
ship_sales AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        hd.hd_vehicle_count AS vehicle_cnt,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_tax > 10
      AND hd.hd_dep_count <= 6
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
)
SELECT demo_sk, vehicle_cnt, total_profit, order_cnt
FROM bill_sales
UNION ALL
SELECT demo_sk, vehicle_cnt, total_profit, order_cnt
FROM ship_sales
WHERE total_profit > 0
ORDER BY total_profit DESC
LIMIT 100
