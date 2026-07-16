WITH item_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        SUM(ss.ss_quantity) AS total_units_sold,
        MAX(p.p_discount_active) AS any_discount_active_flag
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name, i.i_category
    HAVING SUM(inv.inv_quantity_on_hand) > 0
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    total_inventory,
    total_units_sold,
    CASE WHEN total_units_sold = 0 THEN NULL ELSE CAST(total_inventory AS DOUBLE) / total_units_sold END AS inventory_to_sales_ratio,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_units_sold DESC) AS category_sales_rank,
    any_discount_active_flag
FROM item_agg
ORDER BY inventory_to_sales_ratio DESC NULLS LAST
LIMIT 20
