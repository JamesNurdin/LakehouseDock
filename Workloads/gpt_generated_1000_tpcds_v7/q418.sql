SELECT metric_type, year, metric_value
FROM (
   SELECT
       'store_return' AS metric_type,
       dd.d_year AS year,
       SUM(sr.sr_return_amt) AS metric_value
   FROM store_returns sr
   JOIN store s
       ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim dd
       ON sr.sr_returned_date_sk = dd.d_date_sk
   WHERE dd.d_year IN (2002, 2003)
   GROUP BY dd.d_year
   UNION ALL
   SELECT
       'catalog_page' AS metric_type,
       dd.d_year AS year,
       COUNT(*) AS metric_value
   FROM catalog_page cp
   JOIN date_dim dd
       ON cp.cp_start_date_sk = dd.d_date_sk
   WHERE cp.cp_type = 'monthly'
     AND dd.d_year IN (2002, 2003)
   GROUP BY dd.d_year
) AS combined
ORDER BY metric_type, year
