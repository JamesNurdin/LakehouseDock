SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    p.p_promo_name,
    sm.sm_type,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM tpcds.catalog_sales cs
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN tpcds.warehouse w2
  ON inv.inv_warehouse_sk = w2.w_warehouse_sk
JOIN tpcds.promotion p2
  ON p2.p_item_sk = i.i_item_sk
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    p.p_promo_name,
    sm.sm_type
ORDER BY catalog_net_profit DESC
LIMIT 100
