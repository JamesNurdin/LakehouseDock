WITH item_ratings AS (
    SELECT
        pr_item_id AS i_item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COUNT(DISTINCT ss_agg.customer_id) AS distinct_customer_count,
    SUM(ss_agg.quantity) AS total_quantity_sold,
    SUM(i.i_price * ss_agg.quantity) AS total_revenue,
    AVG(COALESCE(ir.avg_rating, 0)) AS avg_item_rating
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.store_id = s.s_store_id
JOIN items i ON ss_agg.item_id = i.i_item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
WHERE i.i_price > 20
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
