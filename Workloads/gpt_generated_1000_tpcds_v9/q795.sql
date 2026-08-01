WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),

joined AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        it_explicit.i_item_id,
        it_explicit.i_current_price,
        it_explicit.i_manager_id,
        it_explicit.i_category,
        it_explicit.i_formulation,
        it_explicit.i_product_name,
        ROW_NUMBER() OVER (ORDER BY inv.inv_date_sk DESC) AS global_rn,
        cat_counts.category_item_count
    FROM sampled_inventory inv
    JOIN item it_explicit
        ON inv.inv_item_sk = it_explicit.i_item_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS category_item_count
        FROM item i2
        WHERE i2.i_category = it_explicit.i_category
    ) cat_counts
    WHERE inv.inv_quantity_on_hand > 500
      AND inv.inv_date_sk BETWEEN 2450800 AND 2451100
      AND it_explicit.i_current_price BETWEEN 10 AND 100
      AND it_explicit.i_manager_id IN (25, 27, 41)
      AND it_explicit.i_formulation NOT LIKE '%olive%'
      AND NOT EXISTS (
          SELECT 1
          FROM item it_ex
          WHERE it_ex.i_item_sk = inv.inv_item_sk
            AND it_ex.i_formulation = 'snow1543775706017405'
      )
)
SELECT
    inv_date_sk,
    inv_warehouse_sk,
    i_category,
    COUNT(*) AS num_records,
    SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(i_current_price) AS avg_price,
    MIN(i_current_price) AS min_price,
    MAX(i_current_price) AS max_price,
    MIN(global_rn) AS min_global_rn,
    MAX(global_rn) AS max_global_rn,
    MIN(category_item_count) AS min_category_item_count,
    MAX(category_item_count) AS max_category_item_count
FROM joined
GROUP BY inv_date_sk, inv_warehouse_sk, i_category
ORDER BY total_quantity_on_hand DESC, avg_price ASC
LIMIT 100
