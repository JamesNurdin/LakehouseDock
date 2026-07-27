WITH returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'large'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cr.cr_return_ship_cost > 100
    GROUP BY cr.cr_item_sk, cr.cr_warehouse_sk, cr.cr_call_center_sk
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
    cc.cc_name,
    w.w_warehouse_name,
    i.i_item_id,
    i.i_formulation,
    ra.total_return_amount,
    ia.total_on_hand,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ra.total_return_amount DESC) AS item_rank_in_warehouse
FROM returns_agg ra
JOIN call_center cc
    ON ra.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON ra.cr_item_sk = i.i_item_sk
JOIN warehouse w
    ON ra.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg ia
    ON ra.cr_item_sk = ia.inv_item_sk
   AND ra.cr_warehouse_sk = ia.inv_warehouse_sk
WHERE i.i_formulation LIKE '%ivory%'
  AND (ia.total_on_hand IS NULL OR ia.total_on_hand > 0)
ORDER BY w.w_warehouse_name, item_rank_in_warehouse
LIMIT 100
