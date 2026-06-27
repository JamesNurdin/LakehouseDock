WITH
    item_rating AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_item_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            s.s_store_name,
            SUM(ss.ss_quantity) AS total_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY ss.ss_store_id, s.s_store_name
    ),
    store_rating AS (
        SELECT
            ss.ss_store_id,
            SUM(ss.ss_quantity * ir.avg_item_rating) / SUM(ss.ss_quantity) AS weighted_avg_rating
        FROM store_sales ss
        JOIN item_rating ir ON ss.ss_item_id = ir.i_item_id
        GROUP BY ss.ss_store_id
    )
SELECT
    agg.ss_store_id,
    agg.s_store_name,
    agg.total_quantity,
    agg.total_revenue,
    agg.distinct_customers,
    COALESCE(rating.weighted_avg_rating, 0) AS weighted_avg_rating
FROM store_sales_agg agg
LEFT JOIN store_rating rating ON agg.ss_store_id = rating.ss_store_id
ORDER BY agg.total_revenue DESC
LIMIT 10
