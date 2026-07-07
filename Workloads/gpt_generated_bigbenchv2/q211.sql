WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_quantity * i.i_price) AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
store_customers AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    SUM(ssa.quantity) AS total_quantity,
    SUM(ssa.revenue) AS total_revenue,
    sc.distinct_customers,
    AVG(its.avg_sentiment) AS avg_item_sentiment
FROM store_sales_agg ssa
JOIN stores s ON ssa.ss_store_id = s.s_store_id
LEFT JOIN item_sentiment its ON ssa.ss_item_id = its.i_item_id
JOIN store_customers sc ON ssa.ss_store_id = sc.ss_store_id
GROUP BY s.s_store_name, sc.distinct_customers
ORDER BY total_revenue DESC
