WITH filtered_sites AS (
   SELECT
     web_site_sk,
     web_site_id,
     web_tax_percentage,
     web_county,
     web_open_date_sk,
     web_close_date_sk,
     web_rec_start_date,
     web_rec_end_date,
     web_mkt_id
   FROM web_site
   WHERE web_tax_percentage >= 0.05
     AND web_tax_percentage <= 0.10
     AND web_county IN ('Jackson County', 'Richland County', 'Maverick County')
)
SELECT *
FROM (
   SELECT
     fd.web_site_id,
     od.d_year,
     cd.d_year,
     COUNT(*) AS site_count,
     SUM(fd.web_tax_percentage) AS total_tax,
     AVG(fd.web_tax_percentage) AS avg_tax,
     MIN(od.d_date) AS min_open_date,
     MAX(cd.d_date) AS max_close_date
   FROM filtered_sites fd
   JOIN date_dim od
     ON fd.web_open_date_sk = od.d_date_sk
   JOIN date_dim cd
     ON fd.web_close_date_sk = cd.d_date_sk
   WHERE od.d_dow = 2
     AND cd.d_dow = 5
     AND fd.web_mkt_id = (SELECT MAX(web_mkt_id) FROM web_site)
   GROUP BY fd.web_site_id, od.d_year, cd.d_year

   UNION

   SELECT
     fd.web_site_id,
     od.d_year,
     cd.d_year,
     COUNT(*) AS site_count,
     SUM(fd.web_tax_percentage) AS total_tax,
     AVG(fd.web_tax_percentage) AS avg_tax,
     MIN(od.d_date) AS min_open_date,
     MAX(cd.d_date) AS max_close_date
   FROM filtered_sites fd
   JOIN date_dim od
     ON fd.web_open_date_sk = od.d_date_sk
   JOIN date_dim cd
     ON fd.web_close_date_sk = cd.d_date_sk
   WHERE od.d_dow = 4
     AND cd.d_dow = 3
     AND EXISTS (
       SELECT 1
       FROM web_site ws
       WHERE ws.web_site_sk = fd.web_site_sk
         AND ws.web_tax_percentage = 0.08
     )
   GROUP BY fd.web_site_id, od.d_year, cd.d_year
) AS combined
ORDER BY total_tax DESC
LIMIT 100
