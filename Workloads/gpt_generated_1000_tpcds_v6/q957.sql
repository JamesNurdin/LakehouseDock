SELECT
  cc.cc_call_center_id,
  CONCAT(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
  sm.sm_ship_mode_id,
  REGEXP_EXTRACT(sm.sm_carrier, '(\\w{3})', 1) AS carrier_code,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  COUNT(*) AS order_count
FROM
  tpcds.catalog_sales cs
JOIN
  tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN
  tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
  tpcds.time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
WHERE
  REGEXP_LIKE(cc.cc_name, 'Center')
  AND sm.sm_type LIKE 'AIR%'
  AND td.t_hour BETWEEN 8 AND 12
GROUP BY
  cc.cc_call_center_id,
  CONCAT(cc.cc_city, ', ', cc.cc_state),
  sm.sm_ship_mode_id,
  REGEXP_EXTRACT(sm.sm_carrier, '(\\w{3})', 1)
HAVING
  SUM(cs.cs_net_profit) > 100000
ORDER BY
  total_net_profit DESC,
  total_sales DESC
LIMIT 100
