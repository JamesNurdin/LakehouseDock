WITH d_sales AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
),
 d_site AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    i.i_category,
    d_sales.d_year,
    p.p_purpose,
    SUM(ss.ss_net_profit)                         AS store_sales_profit,
    SUM(ws.ws_net_profit)                         AS web_sales_profit,
    COALESCE(SUM(sr.sr_net_loss), 0)              AS store_returns_loss,
    COALESCE(SUM(wr.wr_net_loss), 0)              AS web_returns_loss,
    COUNT(DISTINCT ss.ss_ticket_number)           AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number)            AS web_txn_cnt
FROM d_sales
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_returned_date_sk = d_sales.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_date_sk = d_sales.d_date_sk
JOIN warehouse w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
  AND ws.ws_sold_time_sk = t.t_time_sk
  AND ws.ws_item_sk = i.i_item_sk
  AND ws.ws_promo_sk = p.p_promo_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN d_site ds_creation
  ON wp.wp_creation_date_sk = ds_creation.d_date_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN d_site ds_open
  ON we.web_open_date_sk = ds_open.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_returned_date_sk = d_sales.d_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_sales.d_date_sk
WHERE ca.ca_zip LIKE '7____'
GROUP BY i.i_category, d_sales.d_year, p.p_purpose
ORDER BY store_sales_profit DESC
LIMIT 100
