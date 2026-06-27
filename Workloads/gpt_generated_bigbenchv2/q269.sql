WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name AS s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        SUM(ss.ss_quantity * ir.avg_rating) AS weighted_rating_sum,
        SUM(CASE WHEN ir.avg_rating IS NOT NULL THEN ss.ss_quantity ELSE 0 END) AS rating_quantity_sum
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    s_store_name,
    total_quantity,
    total_revenue,
    distinct_customers,
    CASE WHEN rating_quantity_sum > 0 THEN weighted_rating_sum / rating_quantity_sum ELSE NULL END AS avg_item_rating
FROM store_sales_agg
ORDER BY total_quantity DESC
