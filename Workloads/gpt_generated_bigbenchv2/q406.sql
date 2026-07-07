WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_store_id AS store_id,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           NULL AS store_id,
           'web' AS channel
    FROM web_sales ws
)
SELECT i.i_category,
       COUNT(DISTINCT cs.item_id) AS distinct_items_sold,
       SUM(cs.quantity) AS total_quantity_sold,
       SUM(cs.quantity * i.i_price) AS total_revenue,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       COUNT(pr.pr_review_id) AS review_count
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
