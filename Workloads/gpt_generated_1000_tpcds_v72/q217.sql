/* Goal: Rank items within each category by total on‑hand inventory where active TV promotions exist, comparing each item’s quantity to the overall average and filtering on manager, warehouse and quantity thresholds. */
WITH filtered_item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_manager_id,
        p.p_discount_active,
        p.p_channel_tv
    FROM item i
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_tv = 'Y'
      AND i.i_manager_id = 23
),
item_inventory AS (
    SELECT
        ip.i_item_sk,
        ip.i_item_id,
        ip.i_product_name,
        ip.i_category,
        ip.i_manager_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN filtered_item_promo ip
        ON inv.inv_item_sk = ip.i_item_sk
    WHERE inv.inv_quantity_on_hand > 700
      AND inv.inv_warehouse_sk IN (4, 6, 13, 17)
    GROUP BY
        ip.i_item_sk,
        ip.i_item_id,
        ip.i_product_name,
        ip.i_category,
        ip.i_manager_id
    HAVING SUM(inv.inv_quantity_on_hand) > 2000
)
SELECT
    ii.i_item_id,
    ii.i_product_name,
    ii.i_category,
    ii.i_manager_id,
    ii.total_quantity,
    AVG(ii.total_quantity) OVER (PARTITION BY ii.i_category) AS avg_quantity_by_category,
    (SELECT AVG(inv3.inv_quantity_on_hand) FROM inventory inv3) AS overall_avg_quantity,
    CASE
        WHEN ii.total_quantity > (SELECT AVG(inv3.inv_quantity_on_hand) FROM inventory inv3) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS quantity_vs_overall,
    DENSE_RANK() OVER (PARTITION BY ii.i_category ORDER BY ii.total_quantity DESC) AS rank_in_category
FROM item_inventory ii
ORDER BY ii.i_category, rank_in_category
LIMIT 100
