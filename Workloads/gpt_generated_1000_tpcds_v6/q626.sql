WITH
  sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_quantity) AS total_quantity,
      'sales' AS metric_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cd.cd_gender
    HAVING SUM(cs.cs_ext_sales_price) > 10000
  ),
  returns_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(cr.cr_return_amt_inc_tax) AS total_sales,
      SUM(cr.cr_return_quantity) AS total_quantity,
      'returns' AS metric_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cd.cd_gender
    HAVING SUM(cr.cr_return_amt_inc_tax) > 5000
  )
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY year DESC, gender, metric_type
LIMIT 100
