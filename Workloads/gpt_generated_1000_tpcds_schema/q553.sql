WITH
  sales_filtered AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sales_price,
      cp.cp_department,
      cp.cp_type,
      cp.cp_description
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, '\\d{3}')
  ),
  returns_filtered AS (
    SELECT
      cr.cr_order_number,
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cp.cp_department,
      cp.cp_type,
      cp.cp_description
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 100
  ),
  intersect_orders AS (
    SELECT order_num FROM (
      SELECT sf.cs_order_number AS order_num
      FROM sales_filtered sf
      WHERE regexp_like(sf.cp_description, 'Electronics')
      INTERSECT
      SELECT rf.cr_order_number AS order_num
      FROM returns_filtered rf
    )
  )
SELECT
  concat(sf.cp_department, '-', sf.cp_type) AS dept_type,
  'sales' AS record_type,
  sum(sf.cs_sales_price) AS total_amount
FROM sales_filtered sf
WHERE sf.cs_order_number IN (SELECT order_num FROM intersect_orders)
GROUP BY concat(sf.cp_department, '-', sf.cp_type)
UNION DISTINCT
SELECT
  concat(rf.cp_department, '-', rf.cp_type) AS dept_type,
  'returns' AS record_type,
  sum(rf.cr_return_amount) AS total_amount
FROM returns_filtered rf
WHERE rf.cr_order_number IN (SELECT order_num FROM intersect_orders)
GROUP BY concat(rf.cp_department, '-', rf.cp_type)
ORDER BY total_amount DESC
OFFSET 0
LIMIT 100
