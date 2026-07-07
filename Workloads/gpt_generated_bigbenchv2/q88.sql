WITH
    store_agg AS (
        SELECT
            ss_customer_id AS customer_id,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_customer_id
    ),
    web_agg AS (
        SELECT
            ws_customer_id AS customer_id,
            SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_customer_id
    ),
    customer_sales AS (
        SELECT
            c.c_customer_id AS customer_id,
            c.c_name AS customer_name,
            COALESCE(s.store_quantity, 0) AS store_quantity,
            COALESCE(w.web_quantity, 0) AS web_quantity,
            COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
        FROM customers c
        LEFT JOIN store_agg s
            ON s.customer_id = c.c_customer_id
        LEFT JOIN web_agg w
            ON w.customer_id = c.c_customer_id
    )
SELECT
    customer_id,
    customer_name,
    store_quantity,
    web_quantity,
    total_quantity
FROM customer_sales
WHERE total_quantity > 0
ORDER BY total_quantity DESC
LIMIT 10
