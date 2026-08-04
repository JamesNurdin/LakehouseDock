WITH sales_agg AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    CAST(0 AS decimal(15,2)) AS total_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    CAST(NULL AS integer) AS return_transactions,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Medium' END AS sales_level,
    CAST(NULL AS varchar) AS returns_level
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
  GROUP BY d.d_year, i.i_category
  HAVING SUM(ss.ss_ext_sales_price) > 0
),
returns_agg AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    CAST(0 AS decimal(15,2)) AS total_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    CAST(NULL AS integer) AS sales_transactions,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    CAST(NULL AS varchar) AS sales_level,
    CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 50000 THEN 'High' ELSE 'Low' END AS returns_level
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
  GROUP BY d.d_year, i.i_category
  HAVING SUM(sr.sr_return_amt_inc_tax) > 0
)
SELECT
  year,
  category,
  total_sales,
  total_returns,
  sales_transactions,
  return_transactions,
  sales_level,
  returns_level,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC, total_returns DESC) AS rn
FROM (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
) AS combined
ORDER BY year DESC, category ASC, rn ASC
