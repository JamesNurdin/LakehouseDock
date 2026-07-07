WITH customer_store_sales AS (
  SELECT
    ss.ss_store_id,
    s.s_store_name,
    ss.ss_customer_id,
    c.c_name,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN stores s
    ON ss.ss_store_id = s.s_store_id
  JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
  GROUP BY ss.ss_store_id, s.s_store_name, ss.ss_customer_id, c.c_name
),
ranked_customers AS (
  SELECT
    cs.ss_store_id,
    cs.s_store_name,
    cs.ss_customer_id,
    cs.c_name,
    cs.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS customer_rank
  FROM customer_store_sales cs
)
SELECT
  rc.ss_store_id,
  rc.s_store_name,
  rc.ss_customer_id,
  rc.c_name,
  rc.total_quantity,
  rc.customer_rank
FROM ranked_customers rc
WHERE rc.customer_rank <= 3
ORDER BY rc.ss_store_id, rc.customer_rank
