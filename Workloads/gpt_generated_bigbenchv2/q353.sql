WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_category_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        ss.ss_quantity,
        ss.ss_customer_id,
        i.i_item_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
)
SELECT
    scs.s_store_name,
    scs.i_category_name,
    SUM(scs.ss_quantity) AS total_quantity_sold,
    SUM(scs.ss_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(CASE WHEN ir.avg_rating IS NOT NULL THEN scs.ss_quantity END), 0) AS weighted_avg_rating,
    COUNT(DISTINCT scs.ss_customer_id) AS distinct_customers
FROM store_category_sales scs
LEFT JOIN item_avg_rating ir ON scs.i_item_id = ir.i_item_id
GROUP BY scs.s_store_name, scs.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
