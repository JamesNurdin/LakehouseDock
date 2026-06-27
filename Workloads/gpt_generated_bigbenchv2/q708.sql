WITH customer_store_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_name
),
ranked_sales AS (
    SELECT
        css.s_store_name,
        css.c_name,
        css.total_quantity,
        css.transaction_count,
        ROW_NUMBER() OVER (PARTITION BY css.s_store_name ORDER BY css.total_quantity DESC) AS rn
    FROM customer_store_sales css
)
SELECT
    rs.s_store_name,
    rs.c_name,
    rs.total_quantity,
    rs.transaction_count
FROM ranked_sales rs
WHERE rs.rn <= 3
ORDER BY rs.s_store_name, rs.total_quantity DESC
