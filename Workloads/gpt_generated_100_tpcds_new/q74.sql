SELECT
  st.s_store_name,
  sm.sm_type,
  td.t_hour,
  COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
  SUM(ss.ss_net_profit) AS total_net_profit,
  AVG(ss.ss_ext_tax) AS avg_ext_tax,
  MIN(ss.ss_net_paid) AS min_net_paid,
  MAX(ss.ss_net_paid) AS max_net_paid,
  CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
FROM time_dim td
JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
JOIN store st ON ss.ss_store_sk = st.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE td.t_hour = 14
  AND st.s_state = 'CA'
  AND wh.w_city = 'NEW YORK'
  AND sm.sm_type = 'AIR'
  AND c.c_birth_year BETWEEN 1960 AND 1970
GROUP BY st.s_store_name, sm.sm_type, td.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
