WITH sales_agg AS (
  SELECT
    cp.cp_department AS department,
    sm.sm_carrier AS carrier,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cp.cp_department = 'Books'
    AND cs.cs_quantity >= 2
    AND cs.cs_net_paid > 200
    AND hd.hd_vehicle_count >= 0
    AND ca.ca_city IN ('Springfield', 'New Hope')
    AND sm.sm_carrier = 'UPS'
    AND sm.sm_contract = 'O9V6oF8RJnLMmZYd1'
    AND cs.cs_ext_discount_amt < 50
  GROUP BY cp.cp_department, sm.sm_carrier
)
SELECT
  COALESCE(agg.department, 'All Departments') AS department,
  COALESCE(agg.carrier, 'All Carriers') AS carrier,
  SUM(agg.total_ext_sales) AS total_ext_sales,
  SUM(agg.total_net_paid) AS total_net_paid,
  SUM(agg.order_cnt) AS order_cnt,
  SUM(agg.sales_cnt) AS sales_cnt,
  (
    SELECT COUNT(DISTINCT cs_sub.cs_bill_customer_sk)
    FROM catalog_sales cs_sub
    JOIN ship_mode sm_sub ON cs_sub.cs_ship_mode_sk = sm_sub.sm_ship_mode_sk
    JOIN catalog_page cp_sub ON cs_sub.cs_catalog_page_sk = cp_sub.cp_catalog_page_sk
    WHERE (agg.department IS NULL OR cp_sub.cp_department = agg.department)
      AND (agg.carrier IS NULL OR sm_sub.sm_carrier = agg.carrier)
  ) AS distinct_bill_customers,
  CASE WHEN SUM(agg.order_cnt) > 0 THEN SUM(agg.total_net_paid) / SUM(agg.order_cnt) ELSE NULL END AS avg_net_paid_per_order
FROM sales_agg AS agg
GROUP BY ROLLUP (agg.department, agg.carrier)
ORDER BY department, carrier
LIMIT 100
