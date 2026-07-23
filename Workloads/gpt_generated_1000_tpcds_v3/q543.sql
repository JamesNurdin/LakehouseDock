SELECT
  s.s_store_name,
  p.p_promo_name,
  td.t_hour,
  i.i_brand,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_txn_cnt,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_sales_order_cnt,
  SUM(ss.ss_net_profit) AS total_store_net_profit,
  SUM(cs.cs_net_profit) AS total_catalog_net_profit,
  SUM(ws.ws_net_profit) AS total_web_net_profit,
  SUM(ss.ss_net_profit + cs.cs_net_profit + ws.ws_net_profit) AS total_combined_net_profit,
  AVG(CASE WHEN i.i_current_price > 100 THEN ss.ss_ext_discount_amt ELSE cs.cs_ext_discount_amt END) AS avg_discount_conditional,
  CASE WHEN SUM(ss.ss_net_profit + cs.cs_net_profit + ws.ws_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category
FROM
  item i
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_time_sk = td.t_time_sk
    AND cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_order_number = cs.cs_order_number
    AND cr.cr_returned_time_sk = td.t_time_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_time_sk = td.t_time_sk
    AND ws.ws_promo_sk = p.p_promo_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE
  td.t_am_pm = 'PM'
  AND td.t_sub_shift = 'morning'
  AND cc.cc_company = 2
  AND wp.wp_char_count > 1000
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND wp.wp_rec_start_date = DATE '2000-09-03'
GROUP BY
  s.s_store_name,
  p.p_promo_name,
  td.t_hour,
  i.i_brand
ORDER BY
  total_combined_net_profit DESC
LIMIT 100
