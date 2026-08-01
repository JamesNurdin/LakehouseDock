WITH
  sales_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
    UNION
    SELECT ss_ticket_number AS order_number FROM store_sales
    UNION
    SELECT ws_order_number AS order_number FROM web_sales
  ),
  returned_orders AS (
    SELECT cr_order_number AS order_number FROM catalog_returns
    UNION
    SELECT wr_order_number AS order_number FROM web_returns
  ),
  orders_no_return AS (
    SELECT order_number FROM sales_orders
    EXCEPT
    SELECT order_number FROM returned_orders
  )
SELECT
  cp.cp_department,
  sm_cs.sm_ship_mode_id,
  t.t_hour,
  SUM(cs.cs_net_profit) AS total_catalog_net_profit,
  SUM(ss.ss_net_profit) AS total_store_net_profit,
  SUM(ws.ws_net_profit) AS total_web_net_profit,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_orders,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
FROM catalog_sales cs
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN catalog_page cp_r ON cr.cr_catalog_page_sk = cp_r.cp_catalog_page_sk
LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE NOT EXISTS (SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_order_number = cs.cs_order_number)
  AND NOT EXISTS (SELECT 1 FROM web_returns wr2 WHERE wr2.wr_order_number = ws.ws_order_number)
  AND cs.cs_order_number IN (SELECT order_number FROM orders_no_return)
GROUP BY cp.cp_department, sm_cs.sm_ship_mode_id, t.t_hour
ORDER BY total_catalog_net_profit DESC
LIMIT 100
