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
item_reviews AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       isales.total_quantity,
       i.i_price * isales.total_quantity AS total_revenue,
       irev.avg_sentiment,
       irev.review_count
FROM item_sales isales
JOIN items i ON isales.item_id = i.i_item_id
LEFT JOIN item_reviews irev ON i.i_item_id = irev.item_id
WHERE isales.total_quantity > 0
ORDER BY isales.total_quantity DESC
LIMIT 5
