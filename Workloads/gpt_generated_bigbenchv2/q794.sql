WITH item_sales AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_reviews AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       COUNT(DISTINCT i.i_item_id) AS num_items,
       SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
       AVG(COALESCE(r.avg_sentiment, 0)) AS avg_item_sentiment,
       AVG(i.i_price) AS avg_price
FROM items i
LEFT JOIN item_sales s ON s.i_item_id = i.i_item_id
LEFT JOIN item_reviews r ON r.i_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
