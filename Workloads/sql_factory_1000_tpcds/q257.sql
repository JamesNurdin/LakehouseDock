WITH sales_with_dates AS (
  SELECT
    ss.*,
    d.d_date,
    d.d_day_name,
    d.d_year,
    d.d_month_seq
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
call_center_dates AS (
  SELECT
    cc.cc_call_center_sk,
    oc.d_date AS open_date,
    cc_close.d_date AS close_date
  FROM call_center cc
  JOIN date_dim oc ON cc.cc_open_date_sk = oc.d_date_sk
  JOIN date_dim cc_close ON cc.cc_closed_date_sk = cc_close.d_date_sk
),
web_site_dates AS (
  SELECT
    ws.web_site_sk,
    wo.d_date AS open_date,
    wc.d_date AS close_date
  FROM web_site ws
  JOIN date_dim wo ON ws.web_open_date_sk = wo.d_date_sk
  JOIN date_dim wc ON ws.web_close_date_sk = wc.d_date_sk
),
daily_agg AS (
  SELECT
    s.d_date,
    s.d_day_name,
    SUM(s.ss_net_profit) AS daily_profit,
    SUM(s.ss_net_paid) AS daily_paid,
    AVG(s.ss_quantity) AS avg_quantity,
    COUNT(DISTINCT CASE WHEN s.d_date BETWEEN ccad.open_date AND ccad.close_date THEN ccad.cc_call_center_sk END) AS open_cc_cnt,
    COUNT(DISTINCT CASE WHEN s.d_date BETWEEN wsad.open_date AND wsad.close_date THEN wsad.web_site_sk END) AS active_ws_cnt
  FROM sales_with_dates s
  JOIN call_center_dates ccad ON s.d_date BETWEEN ccad.open_date AND ccad.close_date
  JOIN web_site_dates wsad ON s.d_date BETWEEN wsad.open_date AND wsad.close_date
  GROUP BY s.d_date, s.d_day_name
)
SELECT
  d_date,
  d_day_name,
  daily_profit,
  daily_paid,
  avg_quantity,
  SUM(daily_profit) OVER (ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) / 7.0 AS profit_7day_avg,
  CASE
    WHEN daily_profit > (SUM(daily_profit) OVER (ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) / 7.0) * 1.1 THEN 'High'
    WHEN daily_profit < (SUM(daily_profit) OVER (ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) / 7.0) * 0.9 THEN 'Low'
    ELSE 'Medium'
  END AS profit_category,
  open_cc_cnt,
  active_ws_cnt
FROM daily_agg
ORDER BY d_date DESC
LIMIT 30
