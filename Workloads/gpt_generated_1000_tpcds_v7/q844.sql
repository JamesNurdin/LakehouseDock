SELECT
  d.d_fy_week_seq AS fiscal_week,
  SUM(ws.ws_net_profit) AS total_web_net_profit,
  COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_open_cnt,
  MAX(substr(w.w_city, 1, 5)) AS city_prefix,
  MAX(CONCAT(w.w_street_name, ' ', w.w_city)) AS sample_warehouse_address,
  MAX(regexp_extract(cc.cc_street_number, '\\d+')) AS example_call_center_street_num
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
  AND regexp_like(cc.cc_street_type, 'Avenue|Boulevard')
WHERE w.w_city LIKE 'A%'
GROUP BY d.d_fy_week_seq
ORDER BY fiscal_week
