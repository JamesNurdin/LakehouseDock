WITH customer_store_sales AS (
    SELECT
        s.ss_store_id,
        c.c_customer_id,
        c.c_name,
        SUM(s.ss_quantity) AS total_quantity
    FROM store_sales AS s
    JOIN customers AS c
        ON s.ss_customer_id = c.c_customer_id
    GROUP BY s.ss_store_id, c.c_customer_id, c.c_name
)
SELECT
    ss_store_id,
    c_customer_id,
    c_name,
    total_quantity,
    SUM(total_quantity) OVER (PARTITION BY ss_store_id) AS store_total_quantity,
    total_quantity * 1.0 / SUM(total_quantity) OVER (PARTITION BY ss_store_id) AS pct_of_store,
    ROW_NUMBER() OVER (PARTITION BY ss_store_id ORDER BY total_quantity DESC) AS rank_in_store
FROM customer_store_sales
WHERE total_quantity > 10
ORDER BY ss_store_id, rank_in_store
