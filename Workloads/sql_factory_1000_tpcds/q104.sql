WITH daily_closures AS (
  SELECT d.d_date,
         d.d_year,
         COUNT(DISTINCT cc.cc_call_center_sk) AS cc_closed,
         COUNT(DISTINCT s.s_store_sk) AS store_closed,
         COUNT(DISTINCT w.web_site_sk) AS website_closed
  FROM date_dim d
  LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  LEFT JOIN web_site w ON w.web_close_date_sk = d.d_date_sk
  GROUP BY d.d_date, d.d_year
),
 cumulative AS (
  SELECT d_date,
         d_year,
         cc_closed,
         store_closed,
         website_closed,
         (cc_closed + store_closed + website_closed) AS total_closed,
         SUM(cc_closed + store_closed + website_closed) OVER (ORDER BY d_date) AS cumulative_closed
  FROM daily_closures
)
SELECT d_date,
       d_year,
       cc_closed,
       store_closed,
       website_closed,
       total_closed,
       cumulative_closed,
       RANK() OVER (ORDER BY cumulative_closed DESC) AS closure_rank,
       CASE
         WHEN total_closed >= 10 THEN 'High'
         WHEN total_closed >= 5 THEN 'Medium'
         ELSE 'Low'
       END AS closure_level
FROM cumulative
WHERE d_year >= 2015
ORDER BY d_date
