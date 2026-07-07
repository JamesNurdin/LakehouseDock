WITH customer_store_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, c.c_customer_id, c.c_name
)
SELECT
    cs.s_store_name,
    cs.c_name,
    cs.total_quantity
FROM (
    SELECT
        cs.s_store_id,
        cs.s_store_name,
        cs.c_customer_id,
        cs.c_name,
        cs.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.s_store_id ORDER BY cs.total_quantity DESC) AS rn
    FROM customer_store_sales cs
) cs
WHERE cs.rn <= 5
ORDER BY cs.s_store_name, cs.total_quantity DESC
