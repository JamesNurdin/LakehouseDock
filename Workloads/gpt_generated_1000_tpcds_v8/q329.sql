WITH
  sales_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
  ),
  return_orders AS (
    SELECT cr_order_number AS cs_order_number
    FROM catalog_returns
  ),
  orders_without_returns AS (
    SELECT cs_order_number
    FROM sales_orders
    EXCEPT
    SELECT cs_order_number
    FROM return_orders
  ),
  sales_filtered AS (
    SELECT cs.*
    FROM catalog_sales cs
    JOIN orders_without_returns owr
      ON cs.cs_order_number = owr.cs_order_number
  ),
  filtered_customers AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    WHERE regexp_like(c.c_last_name, '^A')
  ),
  page_sales AS (
    SELECT
      cp.cp_catalog_page_id          AS cp_catalog_page_id,
      cp.cp_catalog_number           AS cp_catalog_number,
      cp.cp_description              AS cp_description,
      sf.cs_order_number             AS cs_order_number,
      sf.cs_net_paid                AS cs_net_paid,
      fc.full_name                  AS full_name
    FROM sales_filtered sf
    RIGHT OUTER JOIN catalog_page cp
      ON sf.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN filtered_customers fc
      ON sf.cs_bill_customer_sk = fc.c_customer_sk
    WHERE cp.cp_description LIKE '%book%'
  )
SELECT
  cp_catalog_page_id,
  cp_catalog_number,
  CASE WHEN full_name IS NULL THEN 'No Sales' ELSE full_name END AS customer_name,
  SUM(COALESCE(cs_net_paid, 0))               AS total_net_paid,
  COUNT(cs_order_number)                      AS order_cnt,
  REGEXP_EXTRACT(cp_description, '(\\w+)') AS first_word_desc
FROM page_sales
GROUP BY GROUPING SETS (
  (cp_catalog_page_id, cp_catalog_number, full_name, cp_description),
  (cp_catalog_page_id, cp_catalog_number, cp_description),
  (cp_catalog_page_id, cp_catalog_number),
  ()
)
HAVING SUM(COALESCE(cs_net_paid, 0)) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
