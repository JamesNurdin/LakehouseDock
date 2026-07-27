WITH catalog_part AS (
    SELECT
        sm.sm_type AS ship_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 80000 THEN 'High' ELSE 'Medium' END AS income_category,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sm.sm_type = 'AIR'
      AND ca.ca_location_type = 'apartment'
    GROUP BY
        sm.sm_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 80000 THEN 'High' ELSE 'Medium' END
    HAVING SUM(cs.cs_net_profit) > 10000
),
store_part AS (
    SELECT
        CAST('STORE' AS varchar) AS ship_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 80000 THEN 'High' ELSE 'Medium' END AS income_category,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_location_type = 'condo'
      AND ss.ss_ext_sales_price > 5000
    GROUP BY
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 80000 THEN 'High' ELSE 'Medium' END
    HAVING SUM(ss.ss_net_profit) > 5000
)
SELECT *
FROM (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM store_part
) combined
ORDER BY total_sales DESC
LIMIT 100
