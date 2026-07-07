WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    GROUP BY s.item_id
),
item_sentiment AS (
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(isales.total_quantity, 0)) AS total_quantity_sold,
    AVG(COALESCE(isent.avg_sentiment, 0)) AS avg_sentiment,
    AVG(i.i_price) AS avg_price,
    SUM(COALESCE(isales.total_quantity, 0) * i.i_price) AS total_revenue
FROM items i
LEFT JOIN item_sales isales
    ON isales.item_id = i.i_item_id
LEFT JOIN item_sentiment isent
    ON isent.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
HAVING SUM(COALESCE(isales.total_quantity, 0)) > 0
ORDER BY total_quantity_sold DESC
LIMIT 10
