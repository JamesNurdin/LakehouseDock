WITH sales_by_year AS (
  SELECT d.d_year AS year,
         'sales' AS metric_type,
         SUM(ws.ws_ext_sales_price) AS metric_value
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year
  HAVING SUM(ws.ws_ext_sales_price) > 1000000
),
call_centers_by_year AS (
  SELECT d.d_year AS year,
         'calls' AS metric_type,
         CAST(COUNT(cc.cc_call_center_sk) AS double) AS metric_value
  FROM call_center cc
  JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year
  HAVING COUNT(cc.cc_call_center_sk) > 5
)
SELECT year,
       metric_type,
       metric_value
FROM sales_by_year
UNION ALL
SELECT year,
       metric_type,
       metric_value
FROM call_centers_by_year
ORDER BY year, metric_type
