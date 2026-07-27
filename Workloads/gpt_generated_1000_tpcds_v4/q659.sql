WITH sales_agg AS (
  -- Store channel sales per calendar date
  SELECT
    d.d_date AS sale_date,
    'store' AS channel,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM store_sales ss
  INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_date

  UNION ALL

  -- Web channel sales per calendar date
  SELECT
    d.d_date AS sale_date,
    'web' AS channel,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM web_sales ws
  INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_date
)
SELECT
  sale_date,
  channel,
  total_sales,
  total_profit,
  profit_category
FROM sales_agg
ORDER BY sale_date DESC, total_sales DESC
LIMIT 100
