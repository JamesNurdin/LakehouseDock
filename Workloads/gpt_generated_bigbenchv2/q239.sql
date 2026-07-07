WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        AVG(CAST(pr.pr_sentiment AS double)) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    AVG(isent.avg_sentiment) AS avg_item_sentiment,
    SUM(isent.review_count) AS total_reviews
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.i_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
