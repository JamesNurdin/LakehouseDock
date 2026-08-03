WITH
  ss AS (
    SELECT
      d.d_date AS sale_date,
      d.d_year,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS high_qty_sales,
      COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM (
      SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
    ) ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
    GROUP BY GROUPING SETS (
      (d.d_date, d.d_year),
      (d.d_year)
    )
  ),
  ws AS (
    SELECT
      d.d_date AS sale_date,
      d.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_qty_sales,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
    GROUP BY GROUPING SETS (
      (d.d_date, d.d_year),
      (d.d_year)
    )
  ),
  full_join AS (
    SELECT
      COALESCE(ss.sale_date, ws.sale_date) AS sale_date,
      COALESCE(ss.d_year, ws.d_year) AS d_year,
      ss.total_sales AS store_total_sales,
      ws.total_sales AS web_total_sales,
      ss.high_qty_sales AS store_high_qty_sales,
      ws.high_qty_sales AS web_high_qty_sales,
      ss.distinct_customers AS store_distinct_customers,
      ws.distinct_customers AS web_distinct_customers
    FROM ss
    FULL OUTER JOIN ws
      ON ss.sale_date = ws.sale_date AND ss.d_year = ws.d_year
  ),
  cr AS (
    SELECT
      d.d_date AS sale_date,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_sales,
      SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_qty_sales,
      COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customers
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
    GROUP BY GROUPING SETS (
      (d.d_date, d.d_year),
      (d.d_year)
    )
  )
SELECT
  sale_date,
  d_year,
  store_total_sales,
  web_total_sales,
  store_high_qty_sales,
  web_high_qty_sales,
  store_distinct_customers,
  web_distinct_customers
FROM full_join
UNION ALL
SELECT
  sale_date,
  d_year,
  total_sales AS store_total_sales,
  NULL AS web_total_sales,
  high_qty_sales AS store_high_qty_sales,
  NULL AS web_high_qty_sales,
  distinct_customers AS store_distinct_customers,
  NULL AS web_distinct_customers
FROM cr
ORDER BY d_year DESC, sale_date DESC
OFFSET 0 LIMIT 100
