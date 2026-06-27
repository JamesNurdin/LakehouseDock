WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    sa.s_store_name,
    sa.i_category_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    ra.avg_rating,
    ra.review_count
FROM store_agg sa
LEFT JOIN rating_agg ra
    ON sa.i_category_id = ra.i_category_id
    AND sa.i_category_name = ra.i_category_name
ORDER BY sa.total_revenue DESC
