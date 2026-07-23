SELECT
  t.t_hour,
  i.i_category,
  p.p_promo_name,
  cc.cc_name,
  w.w_warehouse_name,
  s.s_store_name,
  we.web_name,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_sales_price) AS avg_unit_price,
  COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
  MIN(cs.cs_net_profit) AS min_profit,
  MAX(cs.cs_net_profit) AS max_profit
FROM catalog_sales cs
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451550
  AND i.i_category = 'Books'
  AND cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cs.cs_quantity > 5
GROUP BY
  t.t_hour,
  i.i_category,
  p.p_promo_name,
  cc.cc_name,
  w.w_warehouse_name,
  s.s_store_name,
  we.web_name
ORDER BY total_sales DESC
