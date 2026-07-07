WITH sales_union AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_reviews AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    SUM(s.quantity) AS total_quantity,
    SUM(i.i_price * s.quantity) AS total_revenue,
    ir.avg_sentiment,
    ir.review_count
FROM sales_union s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN item_reviews ir ON i.i_item_id = ir.item_id
GROUP BY i.i_item_id, i.i_name, i.i_category, ir.avg_sentiment, ir.review_count
ORDER BY total_quantity DESC
LIMIT 10
