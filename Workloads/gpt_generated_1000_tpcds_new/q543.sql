WITH sampled_cc AS (
   SELECT *
   FROM call_center
   TABLESAMPLE BERNOULLI (10)
   WHERE regexp_like(cc_name, '^A.*')
),
exploded_cc AS (
   SELECT
       cc_call_center_sk,
       cc_name,
       cc_division,
       trim(hour_part) AS hour_part,
       concat(cc_name, ':', trim(hour_part)) AS hour_desc
   FROM sampled_cc
   CROSS JOIN UNNEST(split(cc_hours, ',')) AS t(hour_part)
),
catalog_agg AS (
   SELECT
       ec.cc_division AS division,
       ec.cc_name AS call_center_name,
       NULL AS web_site_name,
       d.d_year AS year,
       SUM(cs.cs_net_paid_inc_tax) AS net_paid_inc_tax
   FROM exploded_cc ec
   JOIN catalog_sales cs ON ec.cc_call_center_sk = cs.cs_call_center_sk
   JOIN date_dim d       ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ec.cc_division, ec.cc_name, d.d_year
),
web_agg AS (
   SELECT
       NULL AS division,
       NULL AS call_center_name,
       ws_site.web_name AS web_site_name,
       d.d_year AS year,
       SUM(ws.ws_net_paid_inc_tax) AS net_paid_inc_tax
   FROM web_sales ws
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   JOIN date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE ws_site.web_name LIKE '%Online%'
     AND d.d_year = 2001
   GROUP BY ws_site.web_name, d.d_year
)
SELECT
   division,
   call_center_name,
   web_site_name,
   year,
   SUM(net_paid_inc_tax) AS total_net_paid_inc_tax
FROM (
   SELECT * FROM catalog_agg
   UNION ALL
   SELECT * FROM web_agg
) combined
GROUP BY ROLLUP (division, call_center_name, web_site_name, year)
ORDER BY division, call_center_name, web_site_name, year
LIMIT 100
