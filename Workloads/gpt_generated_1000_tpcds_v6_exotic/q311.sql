WITH store_ret AS (
  SELECT
    s.s_state AS state,
    d.d_year AS year,
    SUM(sr.sr_return_amt) AS total_amount,
    'store_return' AS source,
    CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
  GROUP BY s.s_state, d.d_year
),
web_sal AS (
  SELECT
    w.web_state AS state,
    d.d_year AS year,
    SUM(ws.ws_net_paid) AS total_amount,
    'web_sale' AS source,
    CASE WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
  FROM web_sales ws
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
  GROUP BY w.web_state, d.d_year
)
SELECT
  combined.state,
  combined.year,
  combined.total_amount,
  combined.source,
  combined.amount_category
FROM (
  SELECT state, year, total_amount, source, amount_category FROM store_ret
  UNION ALL
  SELECT state, year, total_amount, source, amount_category FROM web_sal
) AS combined
ORDER BY combined.year DESC, combined.total_amount DESC
LIMIT 100
