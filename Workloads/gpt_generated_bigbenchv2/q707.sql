WITH store_customer_sales AS (
   SELECT
       ss.ss_store_id AS s_store_id,
       s.s_store_name,
       ss.ss_customer_id AS c_customer_id,
       SUM(ss.ss_quantity) AS total_quantity,
       COUNT(*) AS transaction_count
   FROM store_sales ss
   JOIN stores s ON ss.ss_store_id = s.s_store_id
   GROUP BY ss.ss_store_id, s.s_store_name, ss.ss_customer_id
),
ranked_customers AS (
   SELECT
       scs.s_store_id,
       scs.s_store_name,
       scs.c_customer_id,
       scs.total_quantity,
       scs.transaction_count,
       ROW_NUMBER() OVER (PARTITION BY scs.s_store_id ORDER BY scs.total_quantity DESC) AS rn
   FROM store_customer_sales scs
)
SELECT
   rc.s_store_id,
   rc.s_store_name,
   c.c_name AS customer_name,
   rc.total_quantity,
   rc.transaction_count
FROM ranked_customers rc
JOIN customers c ON rc.c_customer_id = c.c_customer_id
WHERE rc.rn <= 3
ORDER BY rc.s_store_id, rc.rn
