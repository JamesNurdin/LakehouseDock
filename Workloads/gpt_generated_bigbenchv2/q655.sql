WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_review_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.i_category,
    sa.total_quantity_sold,
    sa.distinct_customers,
    ra.avg_review_sentiment,
    ra.review_count
FROM sales_agg sa
LEFT JOIN review_agg ra
    ON sa.i_category_id = ra.i_category_id
ORDER BY sa.total_quantity_sold DESC
LIMIT 100
