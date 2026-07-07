WITH store_sales_agg AS (
    SELECT ss.ss_customer_id AS customer_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_spend
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_customer_id
),
web_sales_agg AS (
    SELECT ws.ws_customer_id AS customer_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_spend
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY ws.ws_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
       COALESCE(ssa.store_spend, 0) + COALESCE(wsa.web_spend, 0) AS total_spend
FROM customers c
LEFT JOIN store_sales_agg ssa ON c.c_customer_id = ssa.customer_id
LEFT JOIN web_sales_agg wsa ON c.c_customer_id = wsa.customer_id
ORDER BY total_spend DESC
LIMIT 5
