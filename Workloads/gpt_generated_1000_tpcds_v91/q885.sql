WITH filtered_a AS (
    SELECT i.i_item_sk
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '(?i)\\b\\w*price\\w*\\b')
      AND i.i_color LIKE '%red%'
    GROUP BY i.i_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) > 700
),
filtered_b AS (
    SELECT i.i_item_sk
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_size = 'large'
      AND REGEXP_LIKE(i.i_manufact, 'pri$')
    GROUP BY i.i_item_sk
    HAVING COUNT(DISTINCT inv.inv_warehouse_sk) >= 2
),
intersected_items AS (
    SELECT i_item_sk FROM filtered_a
    INTERSECT
    SELECT i_item_sk FROM filtered_b
)
SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
    COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count,
    CONCAT(i.i_color, '-', i.i_size) AS color_size,
    substr(i.i_item_id, 1, 5) AS item_id_prefix,
    REGEXP_EXTRACT(MIN(i.i_item_desc), '\\b(\\w{4,})\\b', 1) AS first_long_word
FROM item i
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersected_items)
GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, i.i_color, i.i_size, i.i_item_id
ORDER BY total_quantity_on_hand DESC
LIMIT 100
