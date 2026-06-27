WITH sales_metrics AS (
    SELECT
        ss.ss_store_id AS store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
rating_metrics AS (
    SELECT
        ss.ss_store_id AS store_id,
        AVG(pr.pr_rating) AS avg_item_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sm.total_quantity,
    sm.total_revenue,
    sm.distinct_customers,
    sm.total_revenue / NULLIF(sm.distinct_customers, 0) AS revenue_per_customer,
    rm.avg_item_rating
FROM sales_metrics sm
JOIN stores s ON sm.store_id = s.s_store_id
LEFT JOIN rating_metrics rm ON sm.store_id = rm.store_id
ORDER BY sm.total_revenue DESC
LIMIT 10
