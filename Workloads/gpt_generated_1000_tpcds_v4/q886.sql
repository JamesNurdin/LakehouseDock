/*
Goal: Analyze combined return and sales performance across stores, catalogs, and web channels, segmented by time of day, warehouse state, catalog type, and fee level, while applying realistic filters and a sub‑query existence check.
*/
SELECT
  td.t_hour,
  w.w_state,
  cp.cp_type,
  CASE WHEN sr.sr_fee > 70 THEN 'High' ELSE 'Low' END AS fee_category,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(ws.ws_net_profit) AS total_web_sales_profit,
  AVG(ws.ws_quantity) AS avg_web_quantity,
  MIN(cr.cr_return_tax) AS min_return_tax,
  MAX(p.p_cost) AS max_promo_cost
FROM store_returns sr
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
  sr.sr_fee > 50
  AND cr.cr_return_amount BETWEEN 100 AND 500
  AND cp.cp_catalog_number = 15
  AND r.r_reason_id = 'AAAAAAAACBAAAAAA'
  AND w.w_state = 'CA'
  AND td.t_hour BETWEEN 12 AND 14
  AND EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
      AND wr2.wr_net_loss > 0
  )
GROUP BY
  td.t_hour,
  w.w_state,
  cp.cp_type,
  CASE WHEN sr.sr_fee > 70 THEN 'High' ELSE 'Low' END
ORDER BY
  total_store_return_loss DESC,
  distinct_orders DESC
LIMIT 100
