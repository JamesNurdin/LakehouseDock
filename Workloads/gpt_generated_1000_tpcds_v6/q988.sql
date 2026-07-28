WITH item_cte AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_current_price,
           i.i_brand,
           i.i_category
    FROM item i
    WHERE i.i_current_price BETWEEN 20.00 AND 200.00
      AND i.i_brand = 'Brand#23'
)
SELECT
    i.i_item_id,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_catalog_fees,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(inv.inv_quantity_on_hand) AS min_inventory,
    MAX(inv.inv_quantity_on_hand) AS max_inventory,
    (SELECT sm.sm_type FROM ship_mode sm WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk) AS ship_mode_type
FROM catalog_returns cr
JOIN item_cte i ON cr.cr_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
WHERE cr.cr_return_quantity > 1
  AND cr.cr_return_amount > 100.00
  AND inv.inv_quantity_on_hand > 500
  AND sr.sr_store_credit >= 500
  AND wr.wr_return_ship_cost < 1000
  AND EXISTS (
        SELECT 1 FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm.sm_carrier = 'UPS'
      )
GROUP BY i.i_item_id,
         (SELECT sm.sm_type FROM ship_mode sm WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk)
ORDER BY total_catalog_return_amount DESC
LIMIT 20
