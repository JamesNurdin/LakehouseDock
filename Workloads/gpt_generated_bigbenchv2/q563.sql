WITH store_customer_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY s.s_store_id, s.s_store_name, c.c_customer_id, c.c_name
),
ranked_sales AS (
    SELECT
        s_store_id,
        s_store_name,
        c_customer_id,
        c_name,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_quantity DESC) AS rank
    FROM store_customer_sales
)
SELECT
    s_store_id,
    s_store_name,
    c_customer_id,
    c_name,
    total_quantity,
    rank
FROM ranked_sales
WHERE rank <= 3
ORDER BY s_store_name, rank
