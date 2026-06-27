WITH customer_store_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
ranked_sales AS (
    SELECT
        cs.ss_store_id,
        cs.ss_customer_id,
        cs.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS rn
    FROM customer_store_sales cs
)
SELECT
    s.s_store_name,
    c.c_name,
    rs.total_quantity,
    rs.rn AS customer_rank_in_store
FROM ranked_sales rs
JOIN stores s ON rs.ss_store_id = s.s_store_id
JOIN customers c ON rs.ss_customer_id = c.c_customer_id
WHERE rs.rn <= 5
ORDER BY s.s_store_name, rs.rn
