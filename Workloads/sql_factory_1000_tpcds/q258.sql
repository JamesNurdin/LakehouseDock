WITH call_center_dates AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_division,
    cc.cc_division_name,
    oc.d_date AS open_date,
    cc_close.d_date AS close_date
  FROM call_center cc
  JOIN date_dim oc ON cc.cc_open_date_sk = oc.d_date_sk
  JOIN date_dim cc_close ON cc.cc_closed_date_sk = cc_close.d_date_sk
),
web_site_dates AS (
  SELECT
    ws.web_site_sk,
    ws.web_class,
    wo.d_date AS open_date,
    wc.d_date AS close_date
  FROM web_site ws
  JOIN date_dim wo ON ws.web_open_date_sk = wo.d_date_sk
  JOIN date_dim wc ON ws.web_close_date_sk = wc.d_date_sk
),
sales_with_context AS (
  SELECT
    ss.ss_net_paid,
    ss.ss_net_profit,
    d.d_year,
    d.d_quarter_name,
    ccad.cc_division,
    ccad.cc_division_name,
    wsad.web_class,
    d.d_date
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN call_center_dates ccad ON d.d_date BETWEEN ccad.open_date AND ccad.close_date
  JOIN web_site_dates wsad ON d.d_date BETWEEN wsad.open_date AND wsad.close_date
),
aggregated AS (
  SELECT
    d_year,
    d_quarter_name,
    cc_division,
    cc_division_name,
    web_class,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_net_profit) / NULLIF(SUM(ss_net_paid), 0) AS profit_margin,
    CASE
      WHEN SUM(ss_net_profit) / NULLIF(SUM(ss_net_paid), 0) > 0.20 THEN 'High'
      WHEN SUM(ss_net_profit) / NULLIF(SUM(ss_net_paid), 0) > 0.10 THEN 'Medium'
      ELSE 'Low'
    END AS margin_category
  FROM sales_with_context
  GROUP BY ROLLUP (d_year, d_quarter_name, cc_division, cc_division_name, web_class)
  HAVING SUM(ss_net_paid) IS NOT NULL
)
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY cc_division ORDER BY total_net_profit DESC) AS profit_rank_in_div
FROM aggregated
ORDER BY profit_rank_in_div
LIMIT 50
