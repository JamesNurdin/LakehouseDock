SELECT
    ws.ws_sold_date_sk AS sale_date_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    i.i_current_price,
    ws.ws_quantity,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY ws.ws_net_profit DESC) AS profit_rank_by_brand,
    sm.sm_carrier,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    td.t_hour,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_item_sk = i.i_item_sk) AS total_item_return_amount
FROM web_sales ws
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
  AND sr.sr_return_time_sk = td.t_time_sk
WHERE inv.inv_warehouse_sk IN (1, 3, 15)
  AND inv.inv_quantity_on_hand > 0
  AND i.i_brand = 'Brand#12'
  AND sm.sm_carrier = 'AIRBORNE'
  AND td.t_hour BETWEEN 8 AND 12
  AND ws.ws_quantity >= 5
  AND ws.ws_net_profit > 0
ORDER BY i.i_brand, profit_rank_by_brand, ws.ws_net_profit DESC
LIMIT 100
