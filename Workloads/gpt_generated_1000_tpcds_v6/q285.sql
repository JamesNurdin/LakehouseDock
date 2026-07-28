WITH catalog_year_sales AS (
  SELECT
    d.d_year AS year,
    SUM(cs.cs_net_paid) AS total_sales,
    'catalog' AS channel
  FROM tpcds.catalog_sales cs
  JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
    AND cc.cc_state = 'CA'
  GROUP BY d.d_year
),
web_year_sales AS (
  SELECT
    d.d_year AS year,
    SUM(ws.ws_net_paid) AS total_sales,
    'web' AS channel
  FROM tpcds.web_sales ws
  JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
    AND wsite.web_country = 'United States'
  GROUP BY d.d_year
),
combined AS (
  SELECT * FROM catalog_year_sales
  UNION ALL
  SELECT * FROM web_year_sales
)
SELECT
  c.year,
  c.channel,
  c.total_sales,
  (
    SELECT DISTINCT cc.cc_name
    FROM tpcds.call_center cc
    WHERE cc.cc_state = 'CA'
      AND cc.cc_gmt_offset = (
        SELECT MAX(cc2.cc_gmt_offset)
        FROM tpcds.call_center cc2
        WHERE cc2.cc_state = 'CA'
      )
    LIMIT 1
  ) AS representative_cc_name
FROM combined c
WHERE c.total_sales > (
  SELECT AVG(total_sales) FROM combined
)
ORDER BY c.year, c.channel
