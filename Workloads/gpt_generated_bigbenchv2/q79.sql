SELECT
    s.s_store_id,
    s.s_store_name,
    COUNT(DISTINCT ss.ss_transaction_id) AS total_transactions,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_customer_id) AS unique_customers,
    AVG(ss.ss_quantity) AS avg_quantity_per_transaction
FROM store_sales ss
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_quantity DESC
LIMIT 10
