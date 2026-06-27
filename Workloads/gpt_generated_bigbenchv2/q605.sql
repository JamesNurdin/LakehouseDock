WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        s.ss_store_id,
        SUM(s.ss_quantity) AS total_quantity,
        COUNT(DISTINCT s.ss_transaction_id) AS transaction_cnt
    FROM store_sales s
    JOIN customers c
        ON s.ss_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name, s.ss_store_id
),
store_totals AS (
    SELECT
        ss_store_id,
        SUM(total_quantity) AS store_total_quantity
    FROM customer_sales
    GROUP BY ss_store_id
)
SELECT
    cs.c_customer_id,
    cs.c_name,
    cs.ss_store_id,
    cs.total_quantity,
    cs.transaction_cnt,
    cs.total_quantity * 1.0 / st.store_total_quantity AS quantity_share,
    RANK() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS store_rank
FROM customer_sales cs
JOIN store_totals st
    ON cs.ss_store_id = st.ss_store_id
ORDER BY cs.ss_store_id, store_rank
