SELECT
  w.w_warehouse_name,
  i.i_category,
  d.d_year,
  COUNT(DISTINCT cs.cs_order_number) AS order_count,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_ext_discount_amt) AS avg_discount,
  MIN(cs.cs_ext_sales_price) AS min_sales,
  MAX(cs.cs_ext_sales_price) AS max_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  AND cp.cp_type = 'monthly'
  AND i.i_manager_id = 21
  AND w.w_state = 'CA'
  AND cs.cs_ext_discount_amt > 1000.00
GROUP BY w.w_warehouse_name, i.i_category, d.d_year
ORDER BY total_sales DESC
LIMIT 100
