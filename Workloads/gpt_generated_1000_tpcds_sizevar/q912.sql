WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  returns_customers AS (
    SELECT cr.cr_returning_customer_sk AS cust_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%warranty%'
  ),
  sales_customers AS (
    SELECT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    WHERE ss.ss_net_paid > 500
  ),
  full_join_set AS (
    SELECT COALESCE(r.cust_sk, s.cust_sk) AS cust_sk,
           CASE WHEN r.cust_sk IS NOT NULL THEN 'return' ELSE 'sale' END AS source
    FROM returns_customers r
    FULL OUTER JOIN sales_customers s ON r.cust_sk = s.cust_sk
  ),
  union_set AS (
    SELECT cust_sk FROM returns_customers
    UNION ALL
    SELECT cust_sk FROM sales_customers
  ),
  excluded_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
  ),
  except_set AS (
    SELECT cust_sk FROM union_set
    EXCEPT
    SELECT cust_sk FROM excluded_customers
  ),
  inventory_warehouse AS (
    SELECT w.w_warehouse_sk
    FROM sampled_inventory si
    JOIN warehouse w ON si.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Johnson'
  ),
  intersect_set AS (
    SELECT cust_sk FROM except_set
    INTERSECT
    SELECT w_warehouse_sk FROM inventory_warehouse
  )
SELECT i.cust_sk,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address
FROM intersect_set i
JOIN customer c ON i.cust_sk = c.c_customer_sk
WHERE EXISTS (
  SELECT 1
  FROM web_page wp
  WHERE wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_type = 'product'
)
ORDER BY c.c_last_name, c.c_first_name
OFFSET 0 LIMIT 100
