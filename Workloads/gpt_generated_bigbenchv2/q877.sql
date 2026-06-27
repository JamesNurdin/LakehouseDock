WITH item_rating AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) AS weighted_rating_sum
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_rating ir ON ss.ss_item_id = ir.pr_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(sa.total_quantity, 0) AS total_quantity,
    COALESCE(sa.total_revenue, 0) AS total_revenue,
    COALESCE(sa.distinct_customers, 0) AS distinct_customers,
    CASE
        WHEN COALESCE(sa.total_quantity, 0) > 0 THEN sa.weighted_rating_sum / sa.total_quantity
        ELSE NULL
    END AS avg_rating_weighted
FROM stores s
LEFT JOIN store_sales_agg sa ON s.s_store_id = sa.ss_store_id
ORDER BY total_revenue DESC
LIMIT 10
