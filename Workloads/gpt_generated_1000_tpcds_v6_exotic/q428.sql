WITH warehouse_filtered AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_id,
        w_city,
        w_zip,
        CONCAT(w_city, ' - ', w_zip) AS city_zip,
        CASE 
            WHEN REGEXP_LIKE(w_city, '^S.*') THEN 'StartsWithS'
            ELSE 'Other'
        END AS city_category
    FROM warehouse
    WHERE w_zip LIKE '5%'
      AND REGEXP_LIKE(w_city, '.*[aeiou]{2}.*')
)
SELECT
    wf.w_warehouse_id,
    wf.city_zip,
    wf.city_category,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(CASE WHEN cr.cr_store_credit > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_credit_return_amount,
    (
        SELECT AVG(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = wf.w_warehouse_sk
    ) AS avg_inventory_qty,
    REGEXP_EXTRACT(wf.w_city, '([A-Za-z]+)') AS first_word_city
FROM catalog_returns cr
JOIN warehouse_filtered wf ON cr.cr_warehouse_sk = wf.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = wf.w_warehouse_sk
WHERE cr.cr_return_amount > 0
  AND EXISTS (
      SELECT 1
      FROM inventory i2
      WHERE i2.inv_item_sk = cr.cr_item_sk
        AND i2.inv_quantity_on_hand > 500
  )
GROUP BY
    wf.w_warehouse_id,
    wf.city_zip,
    wf.city_category,
    wf.w_city,
    wf.w_warehouse_sk
ORDER BY total_return_amount DESC
LIMIT 100
