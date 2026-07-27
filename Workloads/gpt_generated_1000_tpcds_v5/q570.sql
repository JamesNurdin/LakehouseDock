SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    it.i_category,
    CASE
        WHEN it.i_current_price > 100 THEN 'Premium'
        ELSE 'Standard'
    END AS price_tier,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(it.i_current_price) AS avg_current_price,
    COUNT(DISTINCT it.i_brand_id) AS distinct_brand_count,
    (SELECT AVG(it2.i_current_price)
     FROM item it2
     JOIN inventory inv2 ON inv2.inv_item_sk = it2.i_item_sk
     WHERE it2.i_category = it.i_category) AS category_avg_price
FROM inventory i
JOIN item it
  ON i.inv_item_sk = it.i_item_sk
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_quantity_on_hand > 100
  AND i.inv_date_sk BETWEEN 2450800 AND 2451100
  AND w.w_state = 'CA'
  AND it.i_current_price > 20.00
  AND it.i_color = 'Red'
  AND EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_item_sk = i.inv_item_sk
          AND i2.inv_quantity_on_hand > 200
      )
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    it.i_category,
    CASE
        WHEN it.i_current_price > 100 THEN 'Premium'
        ELSE 'Standard'
    END
ORDER BY total_quantity_on_hand DESC
LIMIT 100
