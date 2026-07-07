SELECT
    s.s_store_id,
    s.s_store_name,
    c.c_customer_id,
    c.c_name,
    COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_item_id) AS distinct_items
FROM store_sales ss
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY
    s.s_store_id,
    s.s_store_name,
    c.c_customer_id,
    c.c_name
ORDER BY total_quantity DESC
LIMIT 100
