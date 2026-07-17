WITH filtered AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        i.i_item_id,
        i.i_category,
        i.i_current_price
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_date_sk BETWEEN 2450927 AND 2451067
      AND i.i_class = 'furniture'
),
item_totals AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM filtered
    GROUP BY inv_item_sk
),
ranked_items AS (
    SELECT
        f.inv_date_sk,
        f.inv_item_sk,
        f.inv_quantity_on_hand,
        f.i_item_id,
        f.i_category,
        f.i_current_price,
        it.total_qty,
        RANK() OVER (PARTITION BY f.i_category ORDER BY it.total_qty DESC) AS category_quantity_rank,
        ROW_NUMBER() OVER (PARTITION BY f.i_category ORDER BY f.inv_quantity_on_hand DESC) AS category_row_num,
        SUM(f.inv_quantity_on_hand) OVER (
            PARTITION BY f.inv_item_sk
            ORDER BY f.inv_date_sk
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS qty_rolling_3,
        CASE
            WHEN f.inv_quantity_on_hand = 0 THEN 'Out of Stock'
            WHEN f.inv_quantity_on_hand < 100 THEN 'Low Stock'
            ELSE 'Adequate Stock'
        END AS stock_status,
        CASE
            WHEN f.i_current_price >= 100 THEN 'Premium'
            WHEN f.i_current_price >= 50 THEN 'Mid'
            ELSE 'Budget'
        END AS price_tier
    FROM filtered f
    JOIN item_totals it
        ON f.inv_item_sk = it.inv_item_sk
)
SELECT
    inv_date_sk,
    inv_item_sk,
    i_item_id,
    i_category,
    i_current_price,
    inv_quantity_on_hand,
    total_qty,
    qty_rolling_3,
    category_quantity_rank,
    category_row_num,
    stock_status,
    price_tier
FROM ranked_items
ORDER BY i_category, category_quantity_rank, inv_date_sk
