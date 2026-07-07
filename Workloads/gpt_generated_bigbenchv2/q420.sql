WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
)
SELECT i.i_category,
       COUNT(DISTINCT cs.item_id) AS distinct_items_sold,
       SUM(cs.quantity) AS total_quantity_sold,
       AVG(pr.pr_sentiment) AS avg_review_sentiment
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
