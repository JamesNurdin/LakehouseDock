WITH
    customer_sales AS (
        SELECT
            ss.ss_store_id,
            ss.ss_customer_id,
            c.c_name,
            SUM(ss.ss_quantity) AS total_quantity,
            COUNT(*) AS transaction_count
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        GROUP BY ss.ss_store_id, ss.ss_customer_id, c.c_name
    ),
    store_agg AS (
        SELECT
            ss_store_id,
            SUM(total_quantity) AS store_total_quantity,
            COUNT(DISTINCT ss_customer_id) AS distinct_customer_count,
            AVG(total_quantity) AS avg_quantity_per_customer
        FROM customer_sales
        GROUP BY ss_store_id
    ),
    ranked_customers AS (
        SELECT
            cs.ss_store_id,
            cs.ss_customer_id,
            cs.c_name,
            cs.total_quantity,
            ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS customer_rank
        FROM customer_sales cs
    )
SELECT
    s.ss_store_id,
    s.store_total_quantity,
    s.distinct_customer_count,
    s.avg_quantity_per_customer,
    rc.c_name AS top_customer_name,
    rc.total_quantity AS top_customer_quantity
FROM store_agg s
JOIN ranked_customers rc
    ON s.ss_store_id = rc.ss_store_id
WHERE rc.customer_rank = 1
ORDER BY s.store_total_quantity DESC
