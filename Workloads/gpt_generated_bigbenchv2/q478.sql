WITH item_reviews AS (
    SELECT
        i2.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i2 ON pr.pr_item_id = i2.i_item_id
    GROUP BY i2.i_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(item_reviews.avg_rating) AS avg_item_rating,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customer_count,
    SUM(COALESCE(item_reviews.review_count, 0)) AS total_review_count
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_reviews ON i.i_item_id = item_reviews.i_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY total_quantity_sold DESC
