WITH joined_data AS (
  SELECT
    s.s_store_id            AS s_store_id,
    s.s_state               AS s_state,
    sm_cs.sm_type           AS ship_mode_type,
    cs.cs_net_paid          AS cs_net_paid,
    cs.cs_net_profit        AS cs_net_profit,
    ws.ws_net_paid          AS ws_net_paid,
    ws.ws_net_profit        AS ws_net_profit,
    sr.sr_return_amt        AS sr_return_amt,
    sr.sr_net_loss          AS sr_net_loss,
    wr.wr_return_amt        AS wr_return_amt,
    wr.wr_net_loss          AS wr_net_loss,
    p_cs.p_discount_active  AS promo_cs_active,
    p_ws.p_discount_active  AS promo_ws_active
  FROM catalog_sales cs
  JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm_cs           ON cs.cs_ship_mode_sk   = sm_cs.sm_ship_mode_sk
  JOIN warehouse w_cs            ON cs.cs_warehouse_sk   = w_cs.w_warehouse_sk
  JOIN item i_cs                 ON cs.cs_item_sk        = i_cs.i_item_sk
  JOIN promotion p_cs            ON cs.cs_promo_sk       = p_cs.p_promo_sk
  JOIN customer_address ca_bill  ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
  JOIN customer_address ca_ship  ON cs.cs_ship_addr_sk   = ca_ship.ca_address_sk

  JOIN store_returns sr          ON sr.sr_item_sk        = i_cs.i_item_sk
  JOIN customer_address ca_sr_addr ON sr.sr_addr_sk     = ca_sr_addr.ca_address_sk
  JOIN store s                   ON sr.sr_store_sk      = s.s_store_sk

  JOIN web_sales ws              ON ws.ws_item_sk        = i_cs.i_item_sk
  JOIN ship_mode sm_ws           ON ws.ws_ship_mode_sk   = sm_ws.sm_ship_mode_sk
  JOIN warehouse w_ws            ON ws.ws_warehouse_sk   = w_ws.w_warehouse_sk
  JOIN promotion p_ws            ON ws.ws_promo_sk       = p_ws.p_promo_sk
  JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
  JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk

  JOIN web_returns wr            ON wr.wr_order_number   = ws.ws_order_number
  JOIN item i_wr                 ON wr.wr_item_sk        = i_wr.i_item_sk
  JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
  JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
)
SELECT
  s_store_id,
  s_state,
  ship_mode_type,
  SUM(cs_net_paid)        AS total_catalog_sales,
  SUM(ws_net_paid)        AS total_web_sales,
  SUM(sr_return_amt)      AS total_store_return_amount,
  SUM(wr_return_amt)      AS total_web_return_amount,
  SUM(cs_net_profit)      AS total_catalog_profit,
  SUM(ws_net_profit)      AS total_web_profit,
  RANK() OVER (ORDER BY SUM(cs_net_paid) + SUM(ws_net_paid) DESC) AS sales_rank
FROM joined_data
GROUP BY
  s_store_id,
  s_state,
  ship_mode_type
HAVING SUM(cs_net_paid) > 0
ORDER BY sales_rank
LIMIT 100
