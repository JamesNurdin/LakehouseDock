WITH daily_qty AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_by_date
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk = 15
      AND i.i_category = 'Electronics'
      AND i.i_current_price BETWEEN 5 AND 1000
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_brand, i.i_current_price, inv.inv_date_sk
),
with_metrics AS (
    SELECT
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        i_current_price,
        qty_by_date,
        inv_date_sk,
        i_item_sk,
        SUM(qty_by_date) OVER (PARTITION BY i_item_sk ORDER BY inv_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_qty,
        SUM(qty_by_date) OVER (PARTITION BY i_item_sk) AS total_qty,
        MAX(inv_date_sk) OVER (PARTITION BY i_item_sk) AS latest_date_sk,
        CASE
            WHEN i_current_price < 20 THEN 'Low'
            WHEN i_current_price < 100 THEN 'Medium'
            ELSE 'High'
        END AS price_bucket
    FROM daily_qty
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    i_current_price,
    total_qty,
    cumulative_qty,
    latest_date_sk,
    price_bucket,
    RANK() OVER (ORDER BY total_qty DESC) AS overall_qty_rank
FROM with_metrics
WHERE total_qty > 500
ORDER BY overall_qty_rank
LIMIT 100
