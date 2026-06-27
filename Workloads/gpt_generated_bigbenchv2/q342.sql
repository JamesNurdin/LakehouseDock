WITH item_reviews AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_reviews ir ON i.i_item_id = ir.item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    sa.weighted_avg_rating
FROM store_sales_agg sa
JOIN stores s ON sa.store_id = s.s_store_id
ORDER BY sa.total_revenue DESC
LIMIT 10
