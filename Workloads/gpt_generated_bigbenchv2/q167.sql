WITH sales_agg AS (
    SELECT ss_item_id AS item_id, SUM(ss_quantity) AS quantity
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id, SUM(ws_quantity) AS quantity
    FROM web_sales
    GROUP BY ws_item_id
),

total_sales AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM sales_agg
    GROUP BY item_id
),

review_agg AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT 
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    ts.total_quantity,
    ra.avg_sentiment
FROM total_sales ts
JOIN items i ON ts.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY ts.total_quantity DESC
LIMIT 10
