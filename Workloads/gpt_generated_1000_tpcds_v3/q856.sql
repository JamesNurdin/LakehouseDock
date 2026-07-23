WITH store_metrics AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    w.w_warehouse_sk,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM store_returns sr
  JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
  JOIN catalog_sales cs ON cs.cs_sold_time_sk = t_sr.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN (
    SELECT DISTINCT p_promo_sk, p_promo_id, p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
  ) p_active ON cs.cs_promo_sk = p_active.p_promo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
  JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
  JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
  JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = t_sr.t_time_sk
  JOIN (
    SELECT DISTINCT p_promo_sk, p_promo_id, p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
  ) p_active_ws ON ws.ws_promo_sk = p_active_ws.p_promo_sk
  JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
  JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
  JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
  JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
  JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
  JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE t_sr.t_hour BETWEEN 9 AND 17
    AND r_sr.r_reason_id IN ('AAAAAAAABBAAAAAA', 'AAAAAAAANAAAAAAA')
    AND w.w_state = 'CA'
  GROUP BY s.s_store_id, s.s_store_name, s.s_state, w.w_warehouse_sk
)
SELECT
  s_store_id,
  s_store_name,
  s_state,
  store_return_loss,
  catalog_return_loss,
  web_return_loss,
  catalog_sales_profit,
  web_sales_profit,
  total_net_loss,
  total_inventory_qty,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
  (SELECT AVG(p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM store_metrics
ORDER BY total_net_loss DESC
LIMIT 100
