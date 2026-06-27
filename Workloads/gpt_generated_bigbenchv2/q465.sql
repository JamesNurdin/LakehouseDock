WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_enhanced AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        COALESCE(ir.avg_rating, 0) AS avg_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_avg_rating ir
        ON ss.ss_item_id = ir.i_item_id
)
SELECT
    s.s_store_name,
    COUNT(DISTINCT ssse.ss_customer_id) AS distinct_customer_count,
    SUM(ssse.ss_quantity) AS total_quantity_sold,
    SUM(ssse.ss_quantity * ssse.i_price) AS total_revenue,
    SUM(ssse.ss_quantity * ssse.avg_rating) / NULLIF(SUM(ssse.ss_quantity), 0) AS weighted_average_rating
FROM store_sales_enhanced ssse
JOIN stores s
    ON ssse.ss_store_id = s.s_store_id
GROUP BY s.s_store_name
ORDER BY weighted_average_rating DESC NULLS LAST
LIMIT 10
