SELECT s.s_store_name,
       ss.ss_item_id,
       sum(ss.ss_quantity) AS total_quantity,
       count(DISTINCT ss.ss_customer_id) AS unique_customers
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_name, ss.ss_item_id
ORDER BY total_quantity DESC
LIMIT 10
