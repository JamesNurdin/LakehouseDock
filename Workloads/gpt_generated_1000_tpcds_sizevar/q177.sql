SELECT
  cc.cc_call_center_id,
  cc.cc_city,
  SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
  COUNT(*) AS order_count
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_city = 'Glendale'
  AND cs.cs_ext_ship_cost > 500
GROUP BY cc.cc_call_center_id, cc.cc_city
ORDER BY total_ship_cost DESC
LIMIT 10
