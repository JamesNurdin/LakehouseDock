WITH all_sales AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    s.s_state AS state,
    i.i_category AS category,
    ss.ss_net_profit AS profit,
    ss.ss_quantity AS quantity,
    d.d_year AS year,
    d.d_month_seq AS month,
    'store' AS channel
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    c.cc_state,
    i.i_category,
    cs.cs_net_profit,
    cs.cs_quantity,
    d.d_year,
    d.d_month_seq,
    'catalog'
  FROM catalog_sales cs
  JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    w.web_state,
    i.i_category,
    ws.ws_net_profit,
    ws.ws_quantity,
    d.d_year,
    d.d_month_seq,
    'web'
  FROM web_sales ws
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
monthly_sales AS (
  SELECT
    state,
    channel,
    year,
    month,
    SUM(profit) AS month_profit,
    SUM(quantity) AS month_quantity
  FROM all_sales
  GROUP BY state, channel, year, month
),
monthly_cumulative AS (
  SELECT
    state,
    channel,
    year,
    month,
    month_profit,
    month_quantity,
    SUM(month_profit) OVER (PARTITION BY state, channel ORDER BY year, month) AS cumulative_profit,
    SUM(month_quantity) OVER (PARTITION BY state, channel ORDER BY year, month) AS cumulative_quantity
  FROM monthly_sales
),
category_agg AS (
  SELECT
    state,
    channel,
    category,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity,
    ROW_NUMBER() OVER (PARTITION BY state, channel ORDER BY SUM(profit) DESC) AS cat_rank
  FROM all_sales
  GROUP BY state, channel, category
)
SELECT
  ca.state,
  ca.channel,
  SUM(ca.total_profit) AS state_channel_total_profit,
  SUM(ca.total_quantity) AS state_channel_total_quantity,
  ARRAY_AGG(ca.category ORDER BY ca.total_profit DESC)[1] AS top_category,
  ARRAY_AGG(ca.category ORDER BY ca.total_profit DESC)[2] AS second_category,
  ARRAY_AGG(ca.category ORDER BY ca.total_profit DESC)[3] AS third_category,
  MAX(ca.total_profit) FILTER (WHERE ca.cat_rank = 1) AS top_category_profit,
  MAX(ca.total_quantity) FILTER (WHERE ca.cat_rank = 1) AS top_category_quantity,
  mc.cumulative_profit AS total_cumulative_profit,
  mc.cumulative_quantity AS total_cumulative_quantity
FROM category_agg ca
LEFT JOIN (
  SELECT
    state,
    channel,
    cumulative_profit,
    cumulative_quantity,
    ROW_NUMBER() OVER (PARTITION BY state, channel ORDER BY year DESC, month DESC) AS rn
  FROM monthly_cumulative
) mc
  ON ca.state = mc.state
  AND ca.channel = mc.channel
  AND mc.rn = 1
WHERE ca.cat_rank <= 3
GROUP BY ca.state, ca.channel, mc.cumulative_profit, mc.cumulative_quantity
ORDER BY ca.state, ca.channel
