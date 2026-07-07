SELECT
    c.c_customer_id,
    c.c_name,
    COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_item_id) AS distinct_items,
    MIN(ss.ss_ts) AS first_transaction_ts,
    MAX(ss.ss_ts) AS last_transaction_ts
FROM store_sales ss
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name
HAVING SUM(ss.ss_quantity) > 10
ORDER BY total_quantity DESC
LIMIT 100
