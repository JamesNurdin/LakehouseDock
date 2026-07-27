WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_on_hand
   FROM inventory
   GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_category AS category,
    sm_cs.sm_type AS ship_mode,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ss.ss_net_paid) AS store_sales_net,
    SUM(cs.cs_net_paid) AS catalog_sales_net,
    SUM(ws.ws_net_paid) AS web_sales_net,
    SUM(sr.sr_net_loss) AS store_returns_loss,
    SUM(cr.cr_net_loss) AS catalog_returns_loss,
    SUM(wr.wr_net_loss) AS web_returns_loss,
    SUM(ss.ss_net_paid) + SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) -
    (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS net_contribution,
    CASE
        WHEN (SUM(ss.ss_net_paid) + SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) >
             (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss))
        THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    (SELECT MAX(ws2.ws_net_paid)
     FROM web_sales ws2
     WHERE ws2.ws_item_sk = i.i_item_sk) AS max_web_net_paid,
    inv.total_on_hand
FROM store_sales ss
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN date_dim d_we_open ON we.web_open_date_sk = d_we_open.d_date_sk
JOIN date_dim d_we_close ON we.web_close_date_sk = d_we_close.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN inv_agg inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_ss.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND i.i_current_price > 50
  AND ws.ws_quantity > 5
  AND s.s_state = 'CA'
GROUP BY
    i.i_category,
    sm_cs.sm_type,
    inv.total_on_hand,
    i.i_item_sk
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 0
ORDER BY net_contribution DESC
LIMIT 100
