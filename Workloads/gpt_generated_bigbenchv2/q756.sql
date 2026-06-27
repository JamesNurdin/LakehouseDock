WITH store_agg AS (
    SELECT
        stores.s_store_id,
        stores.s_store_name,
        SUM(store_sales.ss_quantity) AS total_quantity,
        COUNT(DISTINCT store_sales.ss_customer_id) AS distinct_customers,
        AVG(store_sales.ss_quantity) AS avg_quantity,
        MAX(store_sales.ss_quantity) AS max_quantity,
        COUNT(*) AS transaction_count
    FROM store_sales
    JOIN stores
        ON store_sales.ss_store_id = stores.s_store_id
    GROUP BY stores.s_store_id, stores.s_store_name
)
SELECT
    s_store_id,
    s_store_name,
    total_quantity,
    distinct_customers,
    avg_quantity,
    max_quantity,
    transaction_count,
    RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
FROM store_agg
ORDER BY total_quantity DESC
LIMIT 10
