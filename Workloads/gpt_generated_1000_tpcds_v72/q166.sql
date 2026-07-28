WITH store_summary AS (
  SELECT
    s.s_city AS location,
    d.d_year AS year,
    d.d_moy AS month,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY s.s_city, d.d_year, d.d_moy
),
catalog_summary AS (
  SELECT
    cp.cp_department AS location,
    d.d_year AS year,
    d.d_moy AS month,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY cp.cp_department, d.d_year, d.d_moy
),
combined AS (
  SELECT
    location,
    year,
    month,
    total_refunded_cash AS total,
    CASE WHEN total_refunded_cash > 1000 THEN 'High' ELSE 'Low' END AS level,
    'store' AS source
  FROM store_summary
  UNION ALL
  SELECT
    location,
    year,
    month,
    total_return_amount AS total,
    CASE WHEN total_return_amount > 5000 THEN 'Big' ELSE 'Small' END AS level,
    'catalog' AS source
  FROM catalog_summary
)
SELECT DISTINCT
  c.location,
  c.year,
  c.month,
  c.total,
  c.level,
  c.source
FROM combined c
WHERE NOT EXISTS (
  SELECT 1
  FROM (
    SELECT year, month FROM store_summary
    INTERSECT
    SELECT year, month FROM catalog_summary
  ) overlap
  WHERE overlap.year = c.year AND overlap.month = c.month
)
ORDER BY c.year DESC, c.month DESC, c.total DESC
LIMIT 100
