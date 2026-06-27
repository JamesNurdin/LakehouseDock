WITH store_customer_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
store_customer_rank AS (
    SELECT
        sca.ss_store_id,
        sca.ss_customer_id,
        sca.total_quantity,
        sca.transaction_count,
        ROW_NUMBER() OVER (PARTITION BY sca.ss_store_id ORDER BY sca.total_quantity DESC) AS rank
    FROM store_customer_agg sca
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_quantity) AS store_total_quantity,
    COUNT(*) AS store_total_transactions,
    COUNT(DISTINCT ss.ss_customer_id) AS store_distinct_customers,
    scr.rank,
    scr.ss_customer_id,
    c.c_name,
    scr.total_quantity,
    scr.transaction_count
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN store_customer_rank scr
    ON ss.ss_store_id = scr.ss_store_id
   AND ss.ss_customer_id = scr.ss_customer_id
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
WHERE scr.rank <= 3
GROUP BY
    s.s_store_id,
    s.s_store_name,
    scr.rank,
    scr.ss_customer_id,
    c.c_name,
    scr.total_quantity,
    scr.transaction_count
ORDER BY s.s_store_id, scr.rank
