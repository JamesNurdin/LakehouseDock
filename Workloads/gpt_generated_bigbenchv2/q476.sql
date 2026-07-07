SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_customer_id) AS unique_customers,
    AVG(ss.ss_quantity) AS avg_quantity
FROM store_sales ss
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_quantity DESC
