WITH promo_inventory AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        i.i_category,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT i.i_item_id) AS distinct_items
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'
      AND inv.inv_quantity_on_hand > 0
      AND p.p_start_date_sk >= 2450806
    GROUP BY p.p_promo_id, p.p_promo_name, i.i_category, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand * i.i_current_price) > 100000
)
SELECT
    pi.*, 
    RANK() OVER (ORDER BY pi.total_inventory_value DESC) AS promo_rank
FROM promo_inventory pi
ORDER BY pi.total_inventory_value DESC
LIMIT 10
