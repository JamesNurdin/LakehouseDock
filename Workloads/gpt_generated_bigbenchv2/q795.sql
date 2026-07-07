WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_category_id,
           SUM(cs.quantity) AS total_quantity_sold
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_category_id
),
item_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT isales.i_item_id,
       isales.i_name,
       isales.i_category,
       isales.total_quantity_sold,
       COALESCE(isent.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(isent.review_count, 0) AS review_count
FROM item_sales isales
LEFT JOIN item_sentiment isent ON isales.i_item_id = isent.i_item_id
ORDER BY isales.total_quantity_sold DESC
LIMIT 10
