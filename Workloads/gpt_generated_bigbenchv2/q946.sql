WITH item_ratings AS (
    SELECT
        i.i_item_id,
        i.i_category_name,
        i.i_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_name, i.i_name
),
store_sales_aggregated AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
)
SELECT
    s.s_store_name,
    ir.i_category_name,
    ir.i_name,
    ss_agg.total_quantity,
    ss_agg.total_revenue,
    ir.avg_rating,
    ir.review_count
FROM store_sales_aggregated ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
JOIN item_ratings ir ON ss_agg.ss_item_id = ir.i_item_id
ORDER BY s.s_store_name, ir.i_category_name, ir.i_name
