/*
  Goal: Compare the total shipped sales amount and the total returned amount for the year 2001, broken down by metric type, and list the results ordered by year descending.
*/
WITH sales_by_year AS (
    SELECT
        d.d_year AS year,
        'sales' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_ship_customer_sk IN (4886950, 4367572)
    GROUP BY d.d_year
),
returns_by_year AS (
    SELECT
        d.d_year AS year,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt_inc_tax) AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_fee > 10
    GROUP BY d.d_year
)
SELECT year, metric_type, amount
FROM sales_by_year
UNION ALL
SELECT year, metric_type, amount
FROM returns_by_year
ORDER BY year DESC, metric_type
