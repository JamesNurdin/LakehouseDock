WITH
  sales_a AS (
    SELECT
      d_year,
      d_quarter_seq AS quarter,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(DISTINCT cs_ext_sales_price) AS distinct_sales_sum,
      COUNT(DISTINCT cs_order_number) AS distinct_orders,
      MAX(cs_sales_price) AS max_price
    FROM catalog_sales
    RIGHT OUTER JOIN date_dim
      ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    WHERE d_year = 2000
      AND cs_quantity > 5
      AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_creation_date_sk = date_dim.d_date_sk
          AND wp.wp_max_ad_count > 2
      )
    GROUP BY d_year, d_quarter_seq
  ),
  sales_b AS (
    SELECT
      d_year,
      d_quarter_seq AS quarter,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(DISTINCT cs_ext_sales_price) AS distinct_sales_sum,
      COUNT(DISTINCT cs_order_number) AS distinct_orders,
      MAX(cs_sales_price) AS max_price
    FROM catalog_sales
    RIGHT OUTER JOIN date_dim
      ON catalog_sales.cs_ship_date_sk = date_dim.d_date_sk
    WHERE d_year = 2001
      AND cs_quantity > 3
      AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_access_date_sk = date_dim.d_date_sk
          AND wp.wp_link_count < 10
      )
    GROUP BY d_year, d_quarter_seq
  ),
  exclude_sales AS (
    SELECT
      d_year,
      d_quarter_seq AS quarter,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(DISTINCT cs_ext_sales_price) AS distinct_sales_sum,
      COUNT(DISTINCT cs_order_number) AS distinct_orders,
      MAX(cs_sales_price) AS max_price
    FROM catalog_sales
    RIGHT OUTER JOIN date_dim
      ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    WHERE d_year = 1999
    GROUP BY d_year, d_quarter_seq
  ),
  combined AS (
    (
      SELECT * FROM sales_a
      UNION ALL
      SELECT * FROM sales_b
    )
    EXCEPT
    SELECT * FROM exclude_sales
  ),
  ranked AS (
    SELECT
      d_year,
      quarter,
      total_sales,
      distinct_sales_sum,
      distinct_orders,
      CASE WHEN max_price > 100 THEN 'HIGH' ELSE 'LOW' END AS price_category,
      ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rk
    FROM combined
    WHERE total_sales > (
      SELECT AVG(cs_ext_sales_price) FROM catalog_sales
    )
  )
SELECT
  d_year,
  quarter,
  total_sales,
  distinct_sales_sum,
  distinct_orders,
  price_category
FROM ranked
WHERE rk <= 5
ORDER BY d_year, total_sales DESC
LIMIT 100
