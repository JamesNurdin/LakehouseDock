WITH store_yearly_profit AS (
  SELECT
    d.d_year AS year,
    SUM(ss.ss_net_profit) AS total_store_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY ROLLUP(d.d_year)
),
catalog_yearly_profit AS (
  SELECT
    d.d_year AS year,
    SUM(cs.cs_net_profit) AS total_catalog_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  GROUP BY ROLLUP(d.d_year)
),
store_years AS (
  SELECT year
  FROM store_yearly_profit
  WHERE year IS NOT NULL
  GROUP BY year
  HAVING SUM(total_store_profit) > (
    SELECT AVG(cs.cs_net_profit)
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
  )
),
catalog_years AS (
  SELECT year
  FROM catalog_yearly_profit
  WHERE year IS NOT NULL
  GROUP BY year
  HAVING SUM(total_catalog_profit) > 0
),
intersect_years AS (
  SELECT year FROM store_years
  INTERSECT
  SELECT year FROM catalog_years
),
avg_store_profit AS (
  SELECT AVG(total_store_profit) AS avg_profit
  FROM store_yearly_profit
  WHERE year IS NOT NULL
)
SELECT
  ROW_NUMBER() OVER (ORDER BY COALESCE(sy.total_store_profit, 0) DESC) AS row_num,
  iy.year,
  CASE WHEN iy.year >= 1998 THEN '1998 and later' ELSE 'Pre-1998' END AS year_category,
  COALESCE(sy.total_store_profit, 0) AS store_total_profit,
  COALESCE(cy.total_catalog_profit, 0) AS catalog_total_profit,
  CASE
    WHEN COALESCE(sy.total_store_profit, 0) > (SELECT avg_profit FROM avg_store_profit) THEN 'Above Avg Store Profit'
    ELSE 'Below Avg Store Profit'
  END AS profit_comparison
FROM intersect_years iy
LEFT JOIN store_yearly_profit sy ON sy.year = iy.year
LEFT JOIN catalog_yearly_profit cy ON cy.year = iy.year
WHERE iy.year IS NOT NULL
ORDER BY store_total_profit DESC, catalog_total_profit DESC
LIMIT 100
