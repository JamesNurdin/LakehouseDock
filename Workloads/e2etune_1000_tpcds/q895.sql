WITH inv_agg AS (
    SELECT inv_item_sk AS item_sk,
           inv_warehouse_sk AS warehouse_sk,
           inv_date_sk AS date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk BETWEEN 2458849 AND 2458949
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
),
sales_agg AS (
    SELECT ws_item_sk AS item_sk,
           ws_warehouse_sk AS warehouse_sk,
           ws_sold_date_sk AS date_sk,
           SUM(ws_quantity) AS total_qty_sold,
           SUM(ws_net_paid) AS total_net_paid,
           SUM(ws_ext_discount_amt) AS total_discount,
           SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458849 AND 2458949
      AND ws_net_profit > 0
    GROUP BY ws_item_sk, ws_warehouse_sk, ws_sold_date_sk
)
SELECT i.item_sk,
       i.warehouse_sk,
       i.date_sk,
       i.total_qty_on_hand,
       s.total_qty_sold,
       s.total_net_paid,
       s.total_net_profit,
       (s.total_qty_sold / NULLIF(i.total_qty_on_hand, 0)) AS sell_through_rate,
       RANK() OVER (PARTITION BY i.warehouse_sk ORDER BY s.total_net_profit DESC) AS profit_rank
FROM inv_agg i
JOIN sales_agg s
  ON i.item_sk = s.item_sk
 AND i.warehouse_sk = s.warehouse_sk
 AND i.date_sk = s.date_sk
WHERE i.total_qty_on_hand > 0
ORDER BY i.warehouse_sk, profit_rank
LIMIT 100
