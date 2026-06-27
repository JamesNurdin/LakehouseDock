WITH item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(LENGTH(c.c_name)) AS avg_customer_name_length,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.pr_item_id
GROUP BY s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
