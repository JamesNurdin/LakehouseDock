WITH store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state AS state,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
  GROUP BY d.d_year, d.d_month_seq, s.s_state
), 
web_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    w.web_state AS state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE d.d_year = 2002
  GROUP BY d.d_year, d.d_month_seq, w.web_state
), 
catalog_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_state AS state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 2002
  GROUP BY d.d_year, d.d_month_seq, cc.cc_state
), 
combined_sales AS (
  SELECT d_year, d_month_seq, state, total_net_paid, total_net_profit, 'store' AS channel FROM store_sales_agg
  UNION ALL
  SELECT d_year, d_month_seq, state, total_net_paid, total_net_profit, 'web' FROM web_sales_agg
  UNION ALL
  SELECT d_year, d_month_seq, state, total_net_paid, total_net_profit, 'catalog' FROM catalog_sales_agg
)
SELECT d_year, d_month_seq, state, channel, total_net_paid, total_net_profit, state_rank
FROM (
  SELECT
    d_year,
    d_month_seq,
    state,
    channel,
    total_net_paid,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS state_rank
  FROM combined_sales
  WHERE state IS NOT NULL
) t
WHERE state_rank <= 5
ORDER BY channel, state_rank
