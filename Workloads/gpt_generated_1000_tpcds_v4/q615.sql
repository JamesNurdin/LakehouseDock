SELECT
  d_cs.d_year AS year,
  s.s_state AS store_state,
  i.i_category AS item_category,
  wp.wp_type AS web_page_type,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_tickets,
  COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
  SUM(cs.cs_net_profit) AS catalog_net_profit,
  SUM(ss.ss_net_profit) AS store_net_profit,
  SUM(ws.ws_net_profit) AS web_net_profit,
  AVG(cs.cs_ext_sales_price) AS avg_catalog_sales_price,
  (
    SELECT AVG(ws2.ws_ext_sales_price)
    FROM web_sales ws2
    JOIN date_dim d_ws2 ON ws2.ws_sold_date_sk = d_ws2.d_date_sk
    WHERE ws2.ws_item_sk = i.i_item_sk
      AND d_ws2.d_year = 2001
  ) AS avg_web_sales_price_for_item,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM store_returns sr2 WHERE sr2.sr_item_sk = i.i_item_sk
    ) THEN 'HasStoreReturn'
    ELSE 'NoStoreReturn'
  END AS store_return_flag
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE d_cs.d_year = 2001
  AND i.i_wholesale_cost > 20
  AND s.s_state = 'CA'
  AND wp.wp_type = 'A'
GROUP BY
  d_cs.d_year,
  s.s_state,
  i.i_category,
  wp.wp_type,
  i.i_item_sk
ORDER BY
  d_cs.d_year,
  s.s_state,
  i.i_category
