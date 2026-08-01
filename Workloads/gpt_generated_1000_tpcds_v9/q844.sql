WITH filtered_catalog AS (
  SELECT
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_net_profit AS net_profit,
    cs.cs_quantity AS quantity,
    cc.cc_name AS call_center_name,
    cc.cc_zip AS call_center_zip,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    w.w_zip AS warehouse_zip,
    td.t_hour AS hour_of_day
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE regexp_like(cc.cc_name, 'Center')
    AND w.w_city LIKE 'W%'
    AND td.t_hour BETWEEN 9 AND 17
),
filtered_web AS (
  SELECT
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_net_profit AS net_profit,
    ws.ws_quantity AS quantity,
    NULL AS call_center_name,
    NULL AS call_center_zip,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    w.w_zip AS warehouse_zip,
    td.t_hour AS hour_of_day
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE w.w_city LIKE 'W%'
    AND td.t_hour BETWEEN 9 AND 17
),
all_sales AS (
  SELECT * FROM filtered_catalog
  UNION ALL
  SELECT * FROM filtered_web
)
SELECT
  COALESCE(call_center_name, 'All Call Centers') AS call_center_name,
  CASE 
    WHEN warehouse_city IS NOT NULL AND warehouse_state IS NOT NULL
    THEN CONCAT(warehouse_city, ', ', warehouse_state)
    ELSE NULL
  END AS warehouse_location,
  MIN(substring(call_center_name, 1, 5)) AS call_center_prefix,
  MAX(regexp_extract(warehouse_zip, '(\\d{5})')) AS warehouse_zip5,
  SUM(sales_amount) AS total_sales,
  SUM(net_profit) AS total_profit,
  SUM(quantity) AS total_quantity,
  COUNT(*) AS transaction_count
FROM all_sales
GROUP BY GROUPING SETS (
  (call_center_name, warehouse_city, warehouse_state),
  (call_center_name),
  (warehouse_city, warehouse_state),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
