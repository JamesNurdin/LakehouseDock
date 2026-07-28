WITH
  store_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(ss.ss_net_paid) AS total_sales,
      'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, i.i_category
  ),
  catalog_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(cs.cs_net_paid) AS total_sales,
      'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, i.i_category
  )
SELECT d_year, i_category, total_sales, channel
FROM store_agg
UNION ALL
SELECT d_year, i_category, total_sales, channel
FROM catalog_agg
ORDER BY d_year, i_category
LIMIT 100
