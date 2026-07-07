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
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(isales.total_quantity) AS category_total_quantity,
       AVG(isent.avg_sentiment) AS category_avg_sentiment
FROM item_sales isales
JOIN items i ON isales.item_id = i.i_item_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY category_total_quantity DESC
LIMIT 10
