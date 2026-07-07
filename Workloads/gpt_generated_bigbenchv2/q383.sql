WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY item_id
),
item_reviews AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(isales.total_quantity) AS total_quantity_sold,
    AVG(i.i_price) AS avg_item_price,
    AVG(irev.avg_sentiment) AS avg_sentiment,
    SUM(irev.review_count) AS total_reviews
FROM item_sales isales
JOIN items i ON isales.item_id = i.i_item_id
LEFT JOIN item_reviews irev ON irev.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
