WITH store_customer_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
store_ranked_customers AS (
    SELECT
        ssc.ss_store_id,
        ssc.ss_customer_id,
        ssc.total_quantity,
        ssc.transaction_count,
        RANK() OVER (PARTITION BY ssc.ss_store_id ORDER BY ssc.total_quantity DESC) AS customer_rank
    FROM store_customer_sales ssc
)
SELECT
    st.s_store_name,
    cu.c_name,
    src.total_quantity,
    src.transaction_count,
    src.customer_rank
FROM store_ranked_customers src
JOIN stores st ON src.ss_store_id = st.s_store_id
JOIN customers cu ON src.ss_customer_id = cu.c_customer_id
WHERE src.customer_rank <= 3
ORDER BY st.s_store_name, src.customer_rank
