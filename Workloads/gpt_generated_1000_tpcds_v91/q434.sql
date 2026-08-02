WITH item_inv AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_category,
           i.i_manufact,
           i.i_size,
           i.i_manager_id,
           i.i_current_price,
           array_agg(DISTINCT inv.inv_warehouse_sk) AS warehouses,
           SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category, i.i_manufact, i.i_size, i.i_manager_id, i.i_current_price
),
returns_agg AS (
    SELECT cr.cr_item_sk,
           SUM(cr.cr_return_amount) AS sum_return_amount,
           SUM(cr.cr_return_quantity) AS total_return_qty,
           COUNT(*) AS return_count,
           AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
    GROUP BY cr.cr_item_sk
)
SELECT
    ii.i_item_id,
    ii.i_category,
    ii.i_manufact,
    ii.i_size,
    ii.i_manager_id,
    ii.i_current_price,
    ii.total_quantity_on_hand,
    ra.sum_return_amount,
    ra.total_return_qty,
    ra.return_count,
    ra.avg_return_amount,
    bench.avg_all_return_amount,
    w.warehouse_sk,
    qty_lateral.qty_per_warehouse,
    SUM(ra.sum_return_amount) OVER (PARTITION BY ii.i_manufact ORDER BY ii.i_current_price DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_return_amount_by_manufact,
    RANK() OVER (PARTITION BY ii.i_category ORDER BY ra.sum_return_amount DESC) AS rank_in_category
FROM item_inv ii
JOIN returns_agg ra ON ra.cr_item_sk = ii.i_item_sk
CROSS JOIN UNNEST(ii.warehouses) AS w (warehouse_sk)
CROSS JOIN LATERAL (
    SELECT SUM(inv2.inv_quantity_on_hand) AS qty_per_warehouse
    FROM inventory inv2
    WHERE inv2.inv_item_sk = ii.i_item_sk
      AND inv2.inv_warehouse_sk = w.warehouse_sk
) AS qty_lateral
CROSS JOIN LATERAL (
    SELECT AVG(cr3.cr_return_amount) AS avg_all_return_amount
    FROM catalog_returns cr3
    WHERE cr3.cr_return_amount > 0
) AS bench
WHERE ii.i_size = 'large'
  AND ii.total_quantity_on_hand > 500
  AND EXISTS (
      SELECT 1
      FROM catalog_returns cr_sub
      JOIN customer c_sub ON cr_sub.cr_refunded_customer_sk = c_sub.c_customer_sk
      WHERE cr_sub.cr_item_sk = ii.i_item_sk
        AND c_sub.c_salutation = 'Mr.'
        AND c_sub.c_birth_day = 20
  )
ORDER BY ii.i_current_price DESC, ra.sum_return_amount DESC
OFFSET 0
LIMIT 100
