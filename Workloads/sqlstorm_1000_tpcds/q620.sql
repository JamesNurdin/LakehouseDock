WITH store_data AS (
  SELECT
    d.d_year AS year,
    s.s_state AS state,
    'Store' AS sales_channel,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS num_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  GROUP BY d.d_year, s.s_state
), web_data AS (
  SELECT
    d.d_year AS year,
    w.web_state AS state,
    'Web' AS sales_channel,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS num_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  GROUP BY d.d_year, w.web_state
)
SELECT
  year,
  state,
  sales_channel,
  total_net_paid,
  total_net_profit,
  total_net_profit / NULLIF(num_sales, 0) AS avg_profit_per_sale,
  total_net_paid / NULLIF(num_sales, 0) AS avg_paid_per_sale,
  SUM(total_net_profit) OVER (PARTITION BY state ORDER BY year) AS running_profit
FROM (
  SELECT * FROM store_data
  UNION ALL
  SELECT * FROM web_data
) AS combined
WHERE year BETWEEN 1999 AND 2002
ORDER BY year, state, sales_channel
