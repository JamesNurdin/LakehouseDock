SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category_name,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
    SUM(ss.ss_quantity * COALESCE(
        (SELECT AVG(pr.pr_rating)
         FROM product_reviews pr
         WHERE pr.pr_item_id = i.i_item_id), 0)
    ) / SUM(ss.ss_quantity) AS weighted_avg_rating
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
WHERE i.i_category_name = 'Electronics'
GROUP BY s.s_store_id, s.s_store_name, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
