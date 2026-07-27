SELECT
    d.d_year,
    cc.cc_division_name,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ss.ss_net_profit + cs.cs_net_profit + ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS store_profit_flag
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
WHERE d.d_fy_week_seq = 9
  AND t.t_hour = 14
  AND c.c_birth_day = 22
  AND c.c_first_name = 'Michael'
  AND cc.cc_division_name = 'anti'
  AND sm.sm_type = 'AIR'
GROUP BY d.d_year, cc.cc_division_name, sm.sm_type
ORDER BY total_profit DESC
LIMIT 100
