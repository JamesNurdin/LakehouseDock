WITH call_center_dates AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_class,
    cc.cc_employees,
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
sales_combined AS (
  SELECT
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_ext_discount_amt,
    d.d_year,
    d.d_month_seq,
    ccad.cc_class,
    CASE WHEN ccad.cc_employees > 100 THEN 'Large' ELSE 'Small' END AS cc_size_category,
    wsad.web_class
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN call_center_dates ccad ON d.d_date BETWEEN ccad.open_date AND ccad.close_date
  JOIN web_site_dates wsad ON d.d_date BETWEEN wsad.open_date AND wsad.close_date
)
SELECT
  cc_class,
  web_class,
  cc_size_category,
  SUM(ss_net_paid) AS total_net_paid,
  SUM(ss_net_profit) AS total_net_profit,
  AVG(ss_ext_discount_amt) AS avg_discount
FROM sales_combined
GROUP BY cc_class, web_class, cc_size_category
