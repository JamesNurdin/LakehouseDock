WITH review_stats AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(rs.avg_sentiment) AS avg_item_sentiment,
    SUM(rs.review_count) AS total_review_count
FROM store_sales ss
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN review_stats rs ON i.i_item_id = rs.pr_item_id
WHERE i.i_price > 20
GROUP BY s.s_store_name, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
