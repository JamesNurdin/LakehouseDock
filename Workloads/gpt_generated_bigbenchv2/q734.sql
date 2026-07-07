SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    SUM(ss.ss_quantity) AS total_units_sold,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
FROM store_sales ss
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_name, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
