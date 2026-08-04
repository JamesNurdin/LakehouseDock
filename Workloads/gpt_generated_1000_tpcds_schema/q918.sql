WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY i.i_item_sk, i.i_product_name
),
cc_warehouse AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state AS cc_state,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state AS w_state
    FROM call_center cc
    FULL OUTER JOIN warehouse w
        ON cc.cc_state = w.w_state
)
SELECT
    isales.i_item_sk,
    isales.i_product_name,
    isales.total_qty,
    isales.total_net_paid,
    cw.cc_name,
    cw.w_warehouse_name
FROM item_sales isales
JOIN inventory inv
    ON isales.i_item_sk = inv.inv_item_sk
JOIN cc_warehouse cw
    ON cw.w_warehouse_sk = inv.inv_warehouse_sk
WHERE isales.i_item_sk IN (
    SELECT item_sk FROM (
        SELECT i_item_sk AS item_sk FROM item_sales WHERE total_qty > 1000
        INTERSECT
        SELECT inv_item_sk AS item_sk FROM inventory WHERE inv_quantity_on_hand > 500
    ) intersected_keys
)
  AND EXISTS (
    SELECT 1 FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = isales.i_item_sk
      AND cs2.cs_net_profit > 0
)
LIMIT 100
