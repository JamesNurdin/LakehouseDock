WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_brand,
        i_units,
        i_formulation,
        regexp_extract(i_formulation, '(\\d+)', 1) AS formulation_number,
        CASE
            WHEN regexp_like(i_formulation, '^\\d+') THEN 'numeric_start'
            ELSE 'alpha_start'
        END AS formulation_type
    FROM item
    WHERE i_units LIKE '%Box%'
      AND regexp_like(i_formulation, '\\d{4,}')
)
SELECT
    f.i_brand,
    f.i_units,
    CONCAT(f.i_brand, ':', f.i_units) AS brand_unit_label,
    SUBSTR(f.i_item_id, 1, 5) AS item_id_prefix,
    f.formulation_type,
    SUM(inv.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT f.i_item_sk) AS distinct_items,
    CASE
        WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'High Stock'
        WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 500 AND 1000 THEN 'Medium Stock'
        ELSE 'Low Stock'
    END AS stock_category
FROM filtered_items f
JOIN inventory inv
    ON inv.inv_item_sk = f.i_item_sk
WHERE inv.inv_warehouse_sk IN (7, 16, 18)
GROUP BY
    f.i_brand,
    f.i_units,
    CONCAT(f.i_brand, ':', f.i_units),
    SUBSTR(f.i_item_id, 1, 5),
    f.formulation_type
ORDER BY total_qty DESC
LIMIT 20
