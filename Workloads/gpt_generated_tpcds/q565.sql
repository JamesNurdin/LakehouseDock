WITH sales AS (
  SELECT
    ws.ws_web_site_sk,
    ws.ws_net_paid,
    ws.ws_ext_discount_amt,
    ws.ws_net_profit,
    d.d_year,
    d.d_month_seq
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
),

sales_agg AS (
  SELECT
    s.ws_web_site_sk,
    s.d_year,
    s.d_month_seq,
    SUM(s.ws_net_paid) AS total_net_paid,
    SUM(s.ws_ext_discount_amt) AS total_discount,
    SUM(s.ws_net_profit) AS total_profit
  FROM sales s
  GROUP BY s.ws_web_site_sk, s.d_year, s.d_month_seq
),

returns AS (
  SELECT
    wr.wr_order_number,
    wr.wr_net_loss,
    d.d_year,
    d.d_month_seq,
    ws.ws_web_site_sk
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  WHERE d.d_year = 2001
),

returns_agg AS (
  SELECT
    r.ws_web_site_sk,
    r.d_year,
    r.d_month_seq,
    SUM(r.wr_net_loss) AS total_return_loss
  FROM returns r
  GROUP BY r.ws_web_site_sk, r.d_year, r.d_month_seq
)
SELECT
  ws_site.web_site_id,
  ws_site.web_name,
  sa.d_year,
  sa.d_month_seq,
  sa.total_net_paid,
  sa.total_discount,
  sa.total_profit,
  COALESCE(ra.total_return_loss, 0) AS total_return_loss,
  (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.ws_web_site_sk = ra.ws_web_site_sk
  AND sa.d_year = ra.d_year
  AND sa.d_month_seq = ra.d_month_seq
JOIN web_site ws_site ON sa.ws_web_site_sk = ws_site.web_site_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
