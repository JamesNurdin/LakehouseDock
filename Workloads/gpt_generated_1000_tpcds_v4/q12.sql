WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
)
SELECT DISTINCT channel,
       sales_year,
       total_sales
FROM (
    SELECT s.s_store_name AS channel,
           fd.d_year AS sales_year,
           SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN filtered_dates fd
      ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_net_paid > 0
    GROUP BY s.s_store_name, fd.d_year

    UNION ALL

    SELECT ws_site.web_name AS channel,
           fd.d_year AS sales_year,
           SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN filtered_dates fd
      ON ws.ws_sold_date_sk = fd.d_date_sk
    JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_net_paid > 0
    GROUP BY ws_site.web_name, fd.d_year
) combined
ORDER BY total_sales DESC
LIMIT 100
