WITH item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_customer_id, ss.ss_item_id
)
SELECT
    s.s_store_name,
    SUM(sis.total_revenue) AS store_total_revenue,
    SUM(sis.total_quantity) AS store_total_quantity,
    COUNT(DISTINCT sis.ss_customer_id) AS distinct_customers,
    CASE WHEN SUM(sis.total_quantity) > 0 THEN
        SUM(sis.total_quantity * COALESCE(ir.avg_rating, 0)) / SUM(sis.total_quantity)
    ELSE NULL END AS weighted_avg_rating,
    SUM(COALESCE(ir.review_count, 0)) AS total_reviews
FROM store_item_sales sis
JOIN stores s ON sis.ss_store_id = s.s_store_id
LEFT JOIN item_ratings ir ON sis.ss_item_id = ir.pr_item_id
GROUP BY s.s_store_name
ORDER BY store_total_revenue DESC
LIMIT 10
