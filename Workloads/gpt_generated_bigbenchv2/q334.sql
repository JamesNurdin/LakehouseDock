WITH store_category_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
),
category_review_stats AS (
    SELECT
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    sc.s_store_name,
    sc.i_category_name,
    sc.total_quantity,
    sc.total_revenue,
    sc.distinct_customers,
    COALESCE(cr.avg_rating, 0) AS avg_rating,
    COALESCE(cr.review_count, 0) AS review_count
FROM store_category_sales sc
LEFT JOIN category_review_stats cr
    ON sc.i_category_name = cr.i_category_name
ORDER BY sc.total_revenue DESC
LIMIT 20
