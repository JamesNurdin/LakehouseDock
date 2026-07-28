WITH sales_agg AS (
  SELECT
    c.c_customer_id,
    cp.cp_department AS department,
    sm.sm_type AS ship_type,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_qty
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE
    cc.cc_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_state = 'CA'
    AND cp.cp_type IN ('monthly', 'quarterly')
    AND cp.cp_start_date_sk BETWEEN 2450905 AND 2451362
    AND wp.wp_link_count > 10
    AND wp.wp_char_count BETWEEN 1500 AND 3000
    AND cs.cs_ext_sales_price > 500
  GROUP BY
    c.c_customer_id,
    cp.cp_department,
    sm.sm_type
)
SELECT
  department,
  ship_type,
  SUM(total_sales) AS dept_ship_sales,
  AVG(total_sales) AS avg_sales_per_customer,
  SUM(total_profit) AS dept_ship_profit,
  CASE
    WHEN SUM(total_profit) > 20000 THEN 'HIGH_PROFIT'
    ELSE 'MODERATE_PROFIT'
  END AS profit_level,
  GROUPING(department) AS grp_department,
  GROUPING(ship_type) AS grp_ship_type
FROM sales_agg
GROUP BY GROUPING SETS (
  (department, ship_type),
  (department),
  ()
)
HAVING SUM(total_sales) > 10000
ORDER BY department, ship_type
LIMIT 100
