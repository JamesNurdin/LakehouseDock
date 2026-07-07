SELECT
    stores.s_store_id,
    stores.s_store_name,
    SUM(store_sales.ss_quantity) AS total_quantity,
    COUNT(DISTINCT store_sales.ss_customer_id) AS unique_customers,
    COUNT(DISTINCT store_sales.ss_transaction_id) AS total_transactions
FROM store_sales
JOIN stores
    ON store_sales.ss_store_id = stores.s_store_id
GROUP BY stores.s_store_id, stores.s_store_name
ORDER BY total_quantity DESC
LIMIT 10
