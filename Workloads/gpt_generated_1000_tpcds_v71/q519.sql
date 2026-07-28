WITH brand_max_price AS (
    SELECT MAX(i_current_price) AS max_price
    FROM item
    WHERE i_brand_id = 6012006
)

SELECT
    'Store Returns' AS source,
    s.s_store_id AS entity_id,
    s.s_store_name AS entity_name,
    SUM(sr.sr_return_amt) AS metric_value,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS status,
    bmp.max_price
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
CROSS JOIN brand_max_price bmp
WHERE i.i_brand_id = 6012006
  AND s.s_state = 'TX'
  AND i.i_category IN (
        SELECT DISTINCT i2.i_category
        FROM item i2
        WHERE i2.i_brand_id = 6012006
      )
GROUP BY s.s_store_id, s.s_store_name, bmp.max_price

UNION ALL

SELECT
    'Inventory' AS source,
    w.w_warehouse_id AS entity_id,
    w.w_warehouse_name AS entity_name,
    SUM(inv.inv_quantity_on_hand) AS metric_value,
    CASE WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'High Stock' ELSE 'Low Stock' END AS status,
    bmp.max_price
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN brand_max_price bmp
WHERE i.i_brand_id = 6012006
  AND w.w_state = 'TX'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_store_sk IN (
                SELECT s_sub.s_store_sk
                FROM store s_sub
                WHERE s_sub.s_state = 'TX'
              )
      )
GROUP BY w.w_warehouse_id, w.w_warehouse_name, bmp.max_price

ORDER BY source, metric_value DESC
LIMIT 100
