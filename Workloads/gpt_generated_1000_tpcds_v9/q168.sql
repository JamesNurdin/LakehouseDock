SELECT
  d.d_year AS year,
  i.i_category AS category,
  p_store.p_promo_name AS promo_name,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(ss.ss_net_profit) AS total_store_profit,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(ws.ws_net_profit) AS total_web_profit,
  SUM(sr.sr_net_loss) AS total_store_returns_loss,
  SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_returns_loss
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p_store
  ON ss.ss_promo_sk = p_store.p_promo_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p_catalog
  ON cs.cs_promo_sk = p_catalog.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = i.i_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p_web
  ON ws.ws_promo_sk = p_web.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT OUTER JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
WHERE d.d_date >= DATE '2000-01-01'
  AND d.d_date < DATE '2001-01-01'
  AND p_store.p_channel_tv = 'N'
  AND i.i_brand = 'Brand#33'
GROUP BY d.d_year, i.i_category, p_store.p_promo_name
ORDER BY d.d_year, i.i_category, total_store_sales DESC
LIMIT 100
