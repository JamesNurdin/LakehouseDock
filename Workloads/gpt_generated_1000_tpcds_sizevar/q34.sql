WITH
  filtered_customers AS (
    SELECT c.c_customer_sk AS cust_sk
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_customer_id, '^A{8}N')
      AND c.c_salutation LIKE 'Mr.%'
  ),
  sales_customers AS (
    SELECT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, 'Gold')
      AND i.i_color LIKE 'Red%'
  ),
  common_customers AS (
    SELECT cust_sk FROM filtered_customers
    INTERSECT
    SELECT cust_sk FROM sales_customers
  ),
  years_2000_2002 AS (
    SELECT DISTINCT d.d_year
    FROM date_dim d
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),
  ship_modes_small AS (
    SELECT sm.sm_ship_mode_sk,
           sm.sm_ship_mode_id
    FROM ship_mode sm
    WHERE sm.sm_code IN ('AIR', 'SEA')
  )
SELECT
  sm.sm_ship_mode_id,
  y.d_year,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
  SUM(cr.cr_return_amount) AS total_return_amount
FROM ship_modes_small sm
CROSS JOIN years_2000_2002 y
JOIN catalog_returns cr
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND d.d_year = y.d_year
JOIN common_customers cc
  ON cr.cr_refunded_customer_sk = cc.cust_sk
GROUP BY
  sm.sm_ship_mode_id,
  y.d_year
ORDER BY total_return_amount DESC
LIMIT 100
