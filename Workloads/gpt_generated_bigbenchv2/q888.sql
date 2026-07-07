WITH combined_sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity
    FROM web_sales ws
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    SUM(cs.quantity) AS total_quantity_sold,
    SUM(cs.quantity * i.i_price) AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_sentiment
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY
    i.i_category,
    i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
