WITH max_income_upper AS (
    SELECT MAX(ib2.ib_upper_bound) AS max_upper
    FROM income_band ib2
)
SELECT
    ib.ib_lower_bound,
    hd.hd_vehicle_count,
    SUM(cs.cs_net_paid_inc_ship) AS total_sales,
    AVG(cs.cs_ext_wholesale_cost) AS avg_wholesale_cost,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_paid_inc_ship) > 4000 THEN 'High' ELSE 'Low' END AS sales_category,
    mu.max_upper AS max_income_upper
FROM catalog_sales cs
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN max_income_upper mu ON 1=1
WHERE cs.cs_ext_wholesale_cost > 1200
  AND cs.cs_net_paid_inc_ship BETWEEN 2000 AND 5000
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 60000
GROUP BY ROLLUP (ib.ib_lower_bound, hd.hd_vehicle_count), mu.max_upper
ORDER BY total_sales DESC, ib.ib_lower_bound ASC
LIMIT 100
