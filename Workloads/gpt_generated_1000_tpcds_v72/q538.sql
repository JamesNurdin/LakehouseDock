WITH store_sales_agg AS (
  SELECT
    d.d_year AS d_year,
    SUM(ss.ss_net_paid) AS total_sales,
    CAST('store' AS varchar) AS channel
  FROM tpcds.store_sales ss
  JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  WHERE s.s_state = 'TX'
  GROUP BY d.d_year
  HAVING SUM(ss.ss_net_paid) > 100000
),
web_sales_agg AS (
  SELECT
    d.d_year AS d_year,
    SUM(ws.ws_net_paid) AS total_sales,
    CAST('web' AS varchar) AS channel
  FROM tpcds.web_sales ws
  JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE w.web_country = 'United States'
  GROUP BY d.d_year
  HAVING SUM(ws.ws_net_paid) > 100000
)
SELECT
  c.d_year,
  c.total_sales,
  c.channel
FROM (
  SELECT d_year, total_sales, channel FROM store_sales_agg
  UNION ALL
  SELECT d_year, total_sales, channel FROM web_sales_agg
) AS c
ORDER BY c.d_year DESC, c.total_sales DESC
LIMIT 100
