WITH item_ratings AS (
    SELECT
        i.i_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity * ir.avg_rating) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_rating,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    agg.total_quantity,
    agg.total_revenue,
    agg.avg_rating,
    agg.distinct_customers
FROM store_sales_agg agg
JOIN stores s ON agg.store_id = s.s_store_id
ORDER BY agg.total_revenue DESC
LIMIT 10
