WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_item_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating,
        SUM(COALESCE(ir.review_cnt, 0)) AS total_reviews
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_name
)
SELECT
    s.s_store_name,
    sis.category_name,
    sis.total_quantity,
    sis.total_revenue,
    sis.weighted_avg_rating,
    sis.total_reviews
FROM store_item_sales sis
JOIN stores s ON sis.ss_store_id = s.s_store_id
ORDER BY sis.total_revenue DESC
LIMIT 20
