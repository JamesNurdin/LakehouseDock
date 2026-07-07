WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id, ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id, ws.ws_quantity AS quantity
    FROM web_sales ws
)
SELECT
    i.i_category,
    SUM(cs.quantity) AS total_quantity,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(pr.pr_review_id) AS review_count
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity DESC
LIMIT 10
