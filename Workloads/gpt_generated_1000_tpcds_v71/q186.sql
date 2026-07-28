WITH item_filtered AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_item_id
    FROM item i
    WHERE regexp_like(i.i_product_name, '^A.*')
),
inventory_agg AS (
    SELECT inv.inv_item_sk,
           inv.inv_warehouse_sk,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    CONCAT(w.w_city, '-', w.w_state) AS location,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) AS total_net_profit,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
    COALESCE(ia.total_on_hand, 0) AS total_inventory_on_hand
FROM catalog_sales cs
JOIN item_filtered i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg ia
    ON ia.inv_item_sk = i.i_item_sk
   AND ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_street_name LIKE '%Street%'
  AND EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_warehouse_sk = w.w_warehouse_sk
          AND inv2.inv_quantity_on_hand > 0
      )
GROUP BY w.w_warehouse_id, w.w_city, w.w_state, ia.total_on_hand
ORDER BY total_net_profit DESC
LIMIT 100
