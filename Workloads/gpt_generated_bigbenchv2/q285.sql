WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity) * i.i_price AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(DISTINCT pr.pr_review_id) AS review_count
FROM items i
LEFT JOIN combined_sales cs ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price
ORDER BY total_revenue DESC
LIMIT 20
