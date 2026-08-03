WITH ss_agg AS (
  SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS sales_category
  FROM store_sales ss
  RIGHT OUTER JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND d.d_date_sk NOT IN (SELECT sr_returned_date_sk FROM store_returns)
  GROUP BY d.d_date, d.d_year, d.d_month_seq
),
ss_ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS rn
  FROM ss_agg
  WHERE total_sales IS NOT NULL
),
cs_agg AS (
  SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 2000 THEN 'High' ELSE 'Low' END AS sales_category
  FROM catalog_sales cs
  RIGHT OUTER JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND d.d_date_sk NOT IN (SELECT sr_returned_date_sk FROM store_returns)
  GROUP BY d.d_date, d.d_year, d.d_month_seq
),
cs_ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS rn
  FROM cs_agg
  WHERE total_sales IS NOT NULL
)
SELECT
  d_date,
  d_year,
  d_month_seq,
  total_sales,
  sales_category
FROM ss_ranked
WHERE rn <= 5

UNION

SELECT
  d_date,
  d_year,
  d_month_seq,
  total_sales,
  sales_category
FROM cs_ranked
WHERE rn <= 5
ORDER BY d_year, d_month_seq, total_sales DESC
LIMIT 100
