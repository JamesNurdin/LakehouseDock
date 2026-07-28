WITH store_agg AS (
  SELECT
    'store' AS channel,
    d.d_month_seq AS month_seq,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_month_seq
),
web_agg AS (
  SELECT
    'web' AS channel,
    d.d_month_seq AS month_seq,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_month_seq
),
combined AS (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
)
SELECT
  channel,
  month_seq,
  total_profit,
  profit_category,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank
FROM combined
ORDER BY channel, profit_rank
