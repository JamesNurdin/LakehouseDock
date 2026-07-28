WITH filtered_inventory AS (
    SELECT
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_weekend
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_month_seq BETWEEN 1 AND 12
      AND i.inv_quantity_on_hand > 100
)
SELECT
    inv_item_sk,
    inv_warehouse_sk,
    d_date,
    inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_quantity_on_hand DESC) AS quantity_rank,
    CASE
        WHEN inv_quantity_on_hand >= 500 THEN 'High'
        WHEN inv_quantity_on_hand >= 200 THEN 'Medium'
        ELSE 'Low'
    END AS quantity_category
FROM filtered_inventory
ORDER BY inv_item_sk, quantity_rank
LIMIT 100
