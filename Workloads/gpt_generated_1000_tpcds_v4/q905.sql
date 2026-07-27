WITH sales_agg AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit
  FROM tpcds.catalog_sales cs
  JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY d.d_year, i.i_category
),
returns_agg AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         SUM(cr.cr_return_amount) AS total_returns,
         SUM(cr.cr_net_loss) AS total_loss
  FROM tpcds.catalog_returns cr
  JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY d.d_year, i.i_category
)
SELECT year,
       category,
       total_sales,
       total_profit,
       CAST(NULL AS decimal(7,2)) AS total_returns,
       CAST(NULL AS decimal(7,2)) AS total_loss,
       'sales' AS source
FROM sales_agg
UNION ALL
SELECT year,
       category,
       CAST(NULL AS decimal(7,2)) AS total_sales,
       CAST(NULL AS decimal(7,2)) AS total_profit,
       total_returns,
       total_loss,
       'returns' AS source
FROM returns_agg
ORDER BY year, category, source
LIMIT 100
