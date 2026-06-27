WITH customer_category_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS total_spend,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    WHERE ss.ss_ts >= '2023-01-01' AND ss.ss_ts < '2024-01-01'
    GROUP BY c.c_customer_id, c.c_name, i.i_category_name
    HAVING SUM(ss.ss_quantity * i.i_price) > 500
)
SELECT
    c_customer_id,
    c_name,
    i_category_name,
    total_spend,
    total_quantity,
    RANK() OVER (PARTITION BY c_customer_id ORDER BY total_spend DESC) AS category_rank
FROM customer_category_sales
ORDER BY total_spend DESC
LIMIT 20
