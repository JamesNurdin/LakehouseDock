WITH
  base_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (5)
    WHERE cs.cs_sold_date_sk IN (
      SELECT d.d_date_sk
      FROM date_dim d
      WHERE d.d_year = 2001
    )
  ),
  return_orders AS (
    SELECT wr.wr_order_number AS order_number
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (
      SELECT d.d_date_sk
      FROM date_dim d
      WHERE d.d_year = 2001
    )
  ),
  promo_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
  ),
  zero_qty_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity = 0
  ),
  combined_orders AS (
    SELECT order_number FROM base_orders
    UNION
    SELECT order_number FROM return_orders
    INTERSECT
    SELECT order_number FROM promo_orders
    EXCEPT
    SELECT order_number FROM zero_qty_orders
  )
SELECT
  COUNT(DISTINCT cu.c_customer_sk) AS distinct_customers,
  COUNT(DISTINCT co.order_number)   AS distinct_orders
FROM combined_orders co
JOIN catalog_sales cs ON cs.cs_order_number = co.order_number
JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
ORDER BY distinct_orders DESC
LIMIT 100
