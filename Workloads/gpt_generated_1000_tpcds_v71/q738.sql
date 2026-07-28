WITH sales_a AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles' ELSE 'Few Vehicles' END AS vehicle_category,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '0-500'
      AND hd.hd_dep_count >= 5
    GROUP BY
        ss.ss_store_sk,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles' ELSE 'Few Vehicles' END
),
sales_b AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles' ELSE 'Few Vehicles' END AS vehicle_category,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = 'Unknown'
      AND hd.hd_dep_count <= 3
    GROUP BY
        ss.ss_store_sk,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles' ELSE 'Few Vehicles' END
)
SELECT
    store_sk,
    vehicle_category,
    total_profit,
    sales_cnt
FROM (
    SELECT store_sk, vehicle_category, total_profit, sales_cnt FROM sales_a
    UNION ALL
    SELECT store_sk, vehicle_category, total_profit, sales_cnt FROM sales_b
) u
ORDER BY total_profit DESC
LIMIT 100
