WITH store_sales_agg AS (
    SELECT ss_store_id,
           SUM(ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss_customer_id) AS distinct_customer_count
    FROM store_sales
    GROUP BY ss_store_id
),
store_customers AS (
    SELECT DISTINCT ss_store_id, ss_customer_id
    FROM store_sales
),
web_agg AS (
    SELECT ws_customer_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT s.s_store_name,
       sa.total_store_quantity,
       sa.distinct_customer_count,
       COALESCE(SUM(wa.total_web_quantity), 0) AS total_web_quantity_for_store_customers
FROM stores s
JOIN store_sales_agg sa ON s.s_store_id = sa.ss_store_id
JOIN store_customers sc ON s.s_store_id = sc.ss_store_id
JOIN customers c ON sc.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg wa ON c.c_customer_id = wa.ws_customer_id
GROUP BY s.s_store_name, sa.total_store_quantity, sa.distinct_customer_count
ORDER BY s.s_store_name
