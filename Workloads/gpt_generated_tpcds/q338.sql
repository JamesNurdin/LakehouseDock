WITH brand_category_inventory AS (
    SELECT
        i.i_brand,
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value,
        AVG(i.i_current_price) AS avg_current_price,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY i.i_brand, i.i_category
)
SELECT
    i_brand,
    i_category,
    total_quantity,
    total_inventory_value,
    avg_current_price,
    avg_wholesale_cost,
    RANK() OVER (PARTITION BY i_category ORDER BY total_inventory_value DESC) AS rank_within_category
FROM brand_category_inventory
ORDER BY i_category, rank_within_category
