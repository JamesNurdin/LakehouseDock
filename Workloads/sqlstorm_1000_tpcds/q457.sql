WITH sales AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS profit,
    SUM(ss.ss_ext_sales_price) AS revenue
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_moy
  UNION ALL
  SELECT
    d.d_year,
    d.d_moy,
    'web',
    SUM(ws.ws_net_profit),
    SUM(ws.ws_ext_sales_price)
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_moy
  UNION ALL
  SELECT
    d.d_year,
    d.d_moy,
    'catalog',
    SUM(cs.cs_net_profit),
    SUM(cs.cs_ext_sales_price)
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_moy
),
returns AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    'store' AS channel,
    SUM(sr.sr_net_loss) AS loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_moy
  UNION ALL
  SELECT
    d.d_year,
    d.d_moy,
    'web',
    SUM(wr.wr_net_loss)
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_moy
  UNION ALL
  SELECT
    d.d_year,
    d.d_moy,
    'catalog',
    SUM(cr.cr_net_loss)
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_moy
),
combined AS (
  SELECT
    s.year,
    s.month,
    s.channel,
    s.profit,
    s.revenue,
    COALESCE(r.loss, 0) AS loss,
    s.profit - COALESCE(r.loss, 0) AS net_profit,
    CASE WHEN s.revenue = 0 THEN 0
         ELSE CAST(s.profit - COALESCE(r.loss, 0) AS DOUBLE) / CAST(s.revenue AS DOUBLE)
    END AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY s.year, s.month ORDER BY (s.profit - COALESCE(r.loss, 0)) DESC) AS profit_rank
  FROM sales s
  LEFT JOIN returns r
    ON s.year = r.year AND s.month = r.month AND s.channel = r.channel
)
SELECT
  year,
  month,
  channel,
  profit,
  loss,
  net_profit,
  profit_margin,
  profit_rank,
  AVG(net_profit) OVER (PARTITION BY channel ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_avg_net_profit
FROM combined
WHERE year BETWEEN 1999 AND 2002
ORDER BY year, month, channel
