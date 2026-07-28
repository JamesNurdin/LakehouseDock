/* goal: Compare store sales totals broken down by household income band and by vehicle count, include subtotals using GROUPING SETS, categorize the sales amount with a CASE expression, and return the highest rows */
WITH income_breakdown AS (
    SELECT 
        h.hd_income_band_sk AS demo_key,
        CONCAT('IncomeBand-', CAST(h.hd_income_band_sk AS VARCHAR)) AS grouping_desc,
        SUM(s.ss_ext_sales_price) AS total_sales
    FROM store_sales s
    JOIN household_demographics h
      ON s.ss_hdemo_sk = h.hd_demo_sk
    WHERE s.ss_wholesale_cost > 30
    GROUP BY GROUPING SETS (
        (h.hd_income_band_sk),
        ()
    )
),
vehicle_breakdown AS (
    SELECT 
        h.hd_vehicle_count AS demo_key,
        CONCAT('VehicleCount-', CAST(h.hd_vehicle_count AS VARCHAR)) AS grouping_desc,
        SUM(s.ss_ext_sales_price) AS total_sales
    FROM store_sales s
    JOIN household_demographics h
      ON s.ss_hdemo_sk = h.hd_demo_sk
    WHERE s.ss_ext_discount_amt < 1000
    GROUP BY GROUPING SETS (
        (h.hd_vehicle_count),
        ()
    )
),
combined AS (
    SELECT demo_key, grouping_desc, total_sales FROM income_breakdown
    UNION ALL
    SELECT demo_key, grouping_desc, total_sales FROM vehicle_breakdown
)
SELECT 
    demo_key,
    grouping_desc,
    total_sales,
    CASE WHEN total_sales > 50000 THEN 'High' ELSE 'Medium' END AS sales_category
FROM combined
ORDER BY total_sales DESC
LIMIT 100
