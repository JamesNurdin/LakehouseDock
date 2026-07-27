WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_ext_list_price
    FROM store_sales ss
    WHERE ss.ss_net_profit > 0
      AND ss.ss_ext_list_price >= 1000
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN hd.hd_vehicle_count >= 3 THEN 'HighVehicle'
        ELSE 'LowVehicle'
    END AS vehicle_category,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(fs.ss_net_profit) AS total_profit,
    AVG(fs.ss_net_profit) AS avg_profit,
    MIN(fs.ss_net_profit) AS min_profit,
    MAX(fs.ss_net_profit) AS max_profit,
    CASE
        WHEN SUM(fs.ss_net_profit) > (
            SELECT AVG(ss_sub.ss_net_profit)
            FROM store_sales ss_sub
            WHERE ss_sub.ss_hdemo_sk = hd.hd_demo_sk
        ) THEN 'AboveDemoAvg'
        ELSE 'BelowDemoAvg'
    END AS profit_vs_demo_avg
FROM filtered_sales fs
JOIN customer c
    ON fs.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE s.s_state = 'CA'
  AND ib.ib_upper_bound >= 150000
  AND hd.hd_vehicle_count >= 2
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN hd.hd_vehicle_count >= 3 THEN 'HighVehicle'
        ELSE 'LowVehicle'
    END,
    hd.hd_demo_sk
ORDER BY total_profit DESC
LIMIT 100
