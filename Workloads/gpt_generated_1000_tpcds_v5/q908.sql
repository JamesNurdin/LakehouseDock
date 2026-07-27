WITH returns_agg AS (
   SELECT
     dd.d_year AS year,
     'Store_Return' AS category,
     SUM(sr.sr_return_amt) AS metric
   FROM store_returns sr
   JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
   JOIN promotion p ON p.p_start_date_sk = dd.d_date_sk
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   WHERE dd.d_year = 2001
   GROUP BY dd.d_year
),
website_agg AS (
   SELECT
     dd.d_year AS year,
     'Web_Site' AS category,
     SUM(ws.web_tax_percentage) AS metric
   FROM web_site ws
   JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
   WHERE dd.d_year = 2001
   GROUP BY dd.d_year
)
SELECT year, category, metric
FROM returns_agg
UNION ALL
SELECT year, category, metric
FROM website_agg
ORDER BY year DESC, metric DESC
LIMIT 100
