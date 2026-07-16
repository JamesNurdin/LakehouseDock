WITH combined_sales AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month,
    cc.cc_state AS state,
    cs.cs_quantity AS quantity,
    cs.cs_net_profit AS profit,
    'catalog' AS channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 2000
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq AS month,
    s.s_state AS state,
    ss.ss_quantity AS quantity,
    ss.ss_net_profit AS profit,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2000
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq AS month,
    ws_site.web_state AS state,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS profit,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE d.d_year = 2000
)
SELECT
  d_year,
  month,
  state,
  channel,
  total_quantity,
  total_profit,
  total_profit / NULLIF(total_quantity, 0) AS profit_per_quantity,
  ROW_NUMBER() OVER (PARTITION BY d_year, month ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT
    d_year,
    month,
    state,
    channel,
    SUM(quantity) AS total_quantity,
    SUM(profit) AS total_profit
  FROM combined_sales
  GROUP BY d_year, month, state, channel
) agg
ORDER BY d_year, month, profit_rank
LIMIT 100
