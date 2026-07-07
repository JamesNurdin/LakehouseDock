WITH review_stats AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sales_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
)
SELECT
    sales_stats.s_store_name,
    sales_stats.i_category,
    sales_stats.total_quantity,
    sales_stats.transaction_count,
    review_stats.avg_sentiment,
    review_stats.review_count
FROM sales_stats
LEFT JOIN review_stats
    ON sales_stats.i_category_id = review_stats.i_category_id
ORDER BY sales_stats.total_quantity DESC
LIMIT 10
