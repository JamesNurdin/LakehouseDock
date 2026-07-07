WITH combined_sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_store_id AS store_id,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        NULL AS store_id,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
)
SELECT
    i.i_category AS category,
    COUNT(DISTINCT i.i_item_id) AS distinct_item_count,
    SUM(cs.quantity) AS total_quantity_sold,
    SUM(i.i_price * cs.quantity) AS total_revenue,
    AVG(i.i_price) AS avg_item_price,
    AVG(pr.pr_sentiment) AS avg_review_sentiment
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
