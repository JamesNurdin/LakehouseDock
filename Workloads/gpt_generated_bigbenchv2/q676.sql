WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_price,
           SUM(cs.quantity) AS total_quantity_sold
    FROM items i
    JOIN combined_sales cs ON cs.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category, i.i_price
),
item_reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category,
       COUNT(DISTINCT isales.i_item_id) AS distinct_items_sold,
       SUM(isales.total_quantity_sold) AS total_quantity,
       SUM(isales.total_quantity_sold * i.i_price) AS total_revenue,
       AVG(isales.total_quantity_sold * i.i_price) AS avg_item_revenue,
       AVG(ireviews.avg_sentiment) AS avg_sentiment,
       SUM(ireviews.review_count) AS total_reviews
FROM items i
JOIN item_sales isales ON isales.i_item_id = i.i_item_id
LEFT JOIN item_reviews ireviews ON ireviews.i_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
LIMIT 10
