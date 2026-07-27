WITH
  store_sales_agg AS (
    SELECT
      d.d_date AS sale_date,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      'store' AS source
    FROM
      store_sales ss
      JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
    GROUP BY
      d.d_date
  ),
  catalog_sales_agg AS (
    SELECT
      d.d_date AS sale_date,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      'catalog' AS source
    FROM
      catalog_sales cs
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
    GROUP BY
      d.d_date
  )
SELECT
  source,
  sale_date,
  total_sales
FROM
  store_sales_agg
UNION ALL
SELECT
  source,
  sale_date,
  total_sales
FROM
  catalog_sales_agg
ORDER BY
  sale_date,
  source
LIMIT 100
