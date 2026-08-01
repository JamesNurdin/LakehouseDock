WITH sampled_inventory AS (
    SELECT
        inv_item_sk,
        inv_quantity_on_hand,
        inv_date_sk,
        inv_warehouse_sk
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
eligible_items AS (
    SELECT p_item_sk AS item_sk FROM promotion WHERE p_discount_active = 'Y'
    INTERSECT
    SELECT inv_item_sk AS item_sk FROM inventory WHERE inv_quantity_on_hand > 600
)
SELECT 
    it.i_item_id,
    it.i_product_name,
    it.i_brand,
    it.i_category,
    si.inv_quantity_on_hand,
    (
        SELECT p.p_promo_name
        FROM promotion p
        WHERE p.p_item_sk = it.i_item_sk
          AND p.p_discount_active = 'Y'
        ORDER BY p.p_cost DESC
        LIMIT 1
    ) AS promo_name,
    (
        SELECT p.p_cost
        FROM promotion p
        WHERE p.p_item_sk = it.i_item_sk
          AND p.p_discount_active = 'Y'
        ORDER BY p.p_cost DESC
        LIMIT 1
    ) AS promo_cost,
    ROW_NUMBER() OVER (PARTITION BY it.i_brand ORDER BY si.inv_quantity_on_hand DESC) AS brand_quantity_rank,
    CASE 
        WHEN (
            SELECT p.p_cost
            FROM promotion p
            WHERE p.p_item_sk = it.i_item_sk
              AND p.p_discount_active = 'Y'
            ORDER BY p.p_cost DESC
            LIMIT 1
        ) > 1000 THEN 'High'
        WHEN (
            SELECT p.p_cost
            FROM promotion p
            WHERE p.p_item_sk = it.i_item_sk
              AND p.p_discount_active = 'Y'
            ORDER BY p.p_cost DESC
            LIMIT 1
        ) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS promo_cost_category
FROM sampled_inventory si
JOIN item it
    ON si.inv_item_sk = it.i_item_sk
WHERE 
    it.i_rec_start_date <= DATE '2000-12-31'
    AND it.i_rec_end_date >= DATE '2000-01-01'
    AND it.i_units IN ('Each', 'Case', 'Lb')
    AND si.inv_quantity_on_hand BETWEEN 300 AND 1000
    AND it.i_item_sk IN (SELECT item_sk FROM eligible_items)
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = it.i_item_sk
          AND p2.p_purpose = 'Discount'
          AND p2.p_discount_active = 'Y'
    )
ORDER BY brand_quantity_rank, it.i_brand, si.inv_quantity_on_hand DESC
LIMIT 100
