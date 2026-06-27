WITH customer_store_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
ranked_customers AS (
    SELECT
        cs.ss_store_id,
        cs.ss_customer_id,
        cs.total_quantity,
        cs.transaction_count,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS rank
    FROM customer_store_sales cs
)
SELECT
    r.rank,
    r.ss_store_id,
    s.s_store_name,
    r.ss_customer_id,
    c.c_name,
    r.total_quantity,
    r.transaction_count
FROM ranked_customers r
JOIN stores s
    ON r.ss_store_id = s.s_store_id
JOIN customers c
    ON r.ss_customer_id = c.c_customer_id
WHERE r.rank <= 5
ORDER BY r.ss_store_id, r.rank
