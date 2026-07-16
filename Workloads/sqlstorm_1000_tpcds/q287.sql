WITH sales_agg AS (
  SELECT
    'store' AS channel,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_store_sk AS store_sk,
    st.s_store_name AS store_name,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_net_paid) AS net_paid,
    COUNT(*) AS orders
  FROM store_sales ss
  JOIN store st ON ss.ss_store_sk = st.s_store_sk
  GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, st.s_store_name

  UNION ALL

  SELECT
    'web' AS channel,
    ws.ws_sold_date_sk AS date_sk,
    NULL AS store_sk,
    NULL AS store_name,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_net_paid) AS net_paid,
    COUNT(*) AS orders
  FROM web_sales ws
  GROUP BY ws.ws_sold_date_sk

  UNION ALL

  SELECT
    'catalog' AS channel,
    cs.cs_sold_date_sk AS date_sk,
    NULL AS store_sk,
    NULL AS store_name,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_net_paid) AS net_paid,
    COUNT(*) AS orders
  FROM catalog_sales cs
  GROUP BY cs.cs_sold_date_sk
),
returns_agg AS (
  SELECT
    'store' AS channel,
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_store_sk AS store_sk,
    st.s_store_name AS store_name,
    SUM(sr.sr_net_loss) AS return_loss,
    SUM(sr.sr_return_amt) AS return_amount,
    COUNT(*) AS returns
  FROM store_returns sr
  JOIN store st ON sr.sr_store_sk = st.s_store_sk
  GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk, st.s_store_name

  UNION ALL

  SELECT
    'web' AS channel,
    wr.wr_returned_date_sk AS date_sk,
    NULL AS store_sk,
    NULL AS store_name,
    SUM(wr.wr_net_loss) AS return_loss,
    SUM(wr.wr_return_amt) AS return_amount,
    COUNT(*) AS returns
  FROM web_returns wr
  GROUP BY wr.wr_returned_date_sk

  UNION ALL

  SELECT
    'catalog' AS channel,
    cr.cr_returned_date_sk AS date_sk,
    NULL AS store_sk,
    NULL AS store_name,
    SUM(cr.cr_net_loss) AS return_loss,
    SUM(cr.cr_return_amount) AS return_amount,
    COUNT(*) AS returns
  FROM catalog_returns cr
  GROUP BY cr.cr_returned_date_sk
),
merged AS (
  SELECT
    s.channel,
    COALESCE(s.store_name, r.store_name) AS store_name,
    d.d_date,
    d.d_year,
    d.d_moy AS month_of_year,
    s.net_profit,
    COALESCE(r.return_loss, 0) AS return_loss,
    (s.net_profit - COALESCE(r.return_loss, 0)) AS adj_profit,
    s.net_paid,
    COALESCE(r.return_amount, 0) AS return_amount,
    s.orders,
    COALESCE(r.returns, 0) AS returns,
    SUM(s.net_profit - COALESCE(r.return_loss, 0)) OVER (PARTITION BY s.channel ORDER BY d.d_date) AS cumulative_adj_profit,
    AVG(s.net_profit - COALESCE(r.return_loss, 0)) OVER (PARTITION BY s.channel ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS mov_avg_adj_profit_7d,
    ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY (s.net_profit - COALESCE(r.return_loss, 0)) DESC) AS profit_rank,
    approx_percentile(s.net_profit - COALESCE(r.return_loss, 0), 0.9) OVER (PARTITION BY s.channel) AS perc90_adj_profit
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.channel = r.channel
   AND s.date_sk = r.date_sk
   AND COALESCE(s.store_sk, -1) = COALESCE(r.store_sk, -1)
  JOIN date_dim d
    ON s.date_sk = d.d_date_sk
)
SELECT
  channel,
  store_name,
  d_date,
  d_year,
  month_of_year,
  net_profit,
  return_loss,
  adj_profit,
  cumulative_adj_profit,
  mov_avg_adj_profit_7d,
  profit_rank,
  perc90_adj_profit
FROM merged
WHERE profit_rank <= 5
ORDER BY channel, profit_rank, d_date
