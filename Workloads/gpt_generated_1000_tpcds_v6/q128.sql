WITH sales_agg AS (
    SELECT
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        ca.ca_state,
        hd.hd_vehicle_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        AVG(ss.ss_ext_wholesale_cost) AS avg_wholesale_cost,
        CASE
            WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle'
            ELSE 'LowVehicle'
        END AS vehicle_category
    FROM store_sales ss
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_state IN ('AK', 'UT', 'NM', 'AZ')
        AND ca.ca_suite_number LIKE 'Suite %'
        AND (hd.hd_vehicle_count IS NULL OR hd.hd_vehicle_count >= 0)
        AND ss.ss_ext_wholesale_cost > 1000
        AND ss.ss_ext_sales_price IS NOT NULL
    GROUP BY
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        ca.ca_state,
        hd.hd_vehicle_count,
        CASE
            WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle'
            ELSE 'LowVehicle'
        END
)
SELECT
    state,
    vehicle_category,
    AVG(total_sales) AS avg_state_sales,
    SUM(total_profit) AS sum_state_profit,
    COUNT(*) AS num_groups,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY SUM(total_profit) DESC) AS profit_rank
FROM (
    SELECT
        ca_state AS state,
        COALESCE(vehicle_category, 'UnknownVehicle') AS vehicle_category,
        total_sales,
        total_profit
    FROM sales_agg
) s
GROUP BY
    state,
    vehicle_category
HAVING
    AVG(total_sales) > 5000
ORDER BY
    sum_state_profit DESC,
    state
LIMIT 100
