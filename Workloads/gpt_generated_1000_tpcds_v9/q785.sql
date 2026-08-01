WITH inventory_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_warehouse_sk = 4
      AND inv_date_sk >= 2450800
    GROUP BY inv_item_sk, inv_warehouse_sk
),
store_returns_agg AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_store_return_qty,
           SUM(sr_return_amt) AS total_store_return_amt,
           AVG(sr_store_credit) AS avg_store_credit
    FROM store_returns
    WHERE sr_return_amt > 100
      AND sr_store_credit > 200
    GROUP BY sr_item_sk
),
catalog_returns_agg AS (
    SELECT cr_item_sk,
           SUM(cr_return_quantity) AS total_catalog_return_qty,
           SUM(cr_return_amount) AS total_catalog_return_amt,
           MAX(cr_return_amount) AS max_catalog_return_amt
    FROM catalog_returns
    WHERE cr_return_amount > 50
    GROUP BY cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    i.i_brand,
    i.i_size,
    inv.total_qty_on_hand,
    sr.total_store_return_qty,
    sr.total_store_return_amt,
    cr.total_catalog_return_qty,
    cr.total_catalog_return_amt,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > sr.total_store_return_amt
    ) AS max_catalog_return_gt_store_return
FROM item i
LEFT JOIN inventory_agg inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN store_returns_agg sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN catalog_returns_agg cr ON cr.cr_item_sk = i.i_item_sk
WHERE i.i_brand_id IN (3002001, 2004002)
  AND i.i_size = 'large'
  AND inv.inv_warehouse_sk = 4
  AND sr.total_store_return_amt > 500
ORDER BY max_catalog_return_gt_store_return DESC
LIMIT 100
