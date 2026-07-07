WITH item_review AS (
    SELECT
        pr_item_id AS item_id,
        SUM(pr_sentiment) AS total_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_store_quantity,
    CASE WHEN SUM(ir.review_count) > 0 THEN SUM(ir.total_sentiment) / SUM(ir.review_count) ELSE NULL END AS avg_review_sentiment,
    SUM(ir.review_count) AS total_review_count,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customer_count
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_review ir ON i.i_item_id = ir.item_id
GROUP BY s.s_store_name, i.i_category
ORDER BY total_store_quantity DESC
