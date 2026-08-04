WITH store_agg AS (
  SELECT
    d.d_year AS year,
    'Store' AS channel,
    SUM(ss.ss_net_paid) AS total_net_paid,
    CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM tpcds.store_sales ss
  JOIN tpcds.date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year
),
catalog_agg AS (
  SELECT
    d.d_year AS year,
    'Catalog' AS channel,
    SUM(cs.cs_net_paid) AS total_net_paid,
    CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM tpcds.catalog_sales cs
  JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM catalog_agg
ORDER BY year, channel
LIMIT 100
