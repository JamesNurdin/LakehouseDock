WITH unified_sales AS (
 SELECT
  s.cs_bill_customer_sk AS customer_sk,
  s.cs_bill_cdemo_sk AS demo_sk,
  s.cs_sold_date_sk AS sold_date_sk,
  s.cs_net_profit AS profit,
  i.i_category,
  i.i_class
 FROM catalog_sales s
 JOIN item i ON s.cs_item_sk = i.i_item_sk
 UNION ALL
 SELECT
  s.ss_customer_sk,
  s.ss_cdemo_sk,
  s.ss_sold_date_sk,
  s.ss_net_profit,
  i.i_category,
  i.i_class
 FROM store_sales s
 JOIN item i ON s.ss_item_sk = i.i_item_sk
 UNION ALL
 SELECT
  s.ws_bill_customer_sk,
  s.ws_bill_cdemo_sk,
  s.ws_sold_date_sk,
  s.ws_net_profit,
  i.i_category,
  i.i_class
 FROM web_sales s
 JOIN item i ON s.ws_item_sk = i.i_item_sk
),
sales_with_date AS (
 SELECT
  us.customer_sk,
  us.demo_sk,
  d.d_year,
  d.d_month_seq,
  us.i_category,
  us.i_class,
  us.profit
 FROM unified_sales us
 JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
),
agg_sales AS (
 SELECT
  swd.customer_sk,
  swd.demo_sk,
  swd.d_year,
  swd.i_category,
  swd.i_class,
  SUM(swd.profit) AS total_profit,
  COUNT(*) AS transaction_count,
  SUM(swd.profit) / COUNT(*) AS avg_profit_per_txn
 FROM sales_with_date swd
 GROUP BY swd.customer_sk, swd.demo_sk, swd.d_year, swd.i_category, swd.i_class
),
demo_joined AS (
 SELECT
  a.*,
  cd.cd_gender,
  cd.cd_marital_status,
  cd.cd_education_status
 FROM agg_sales a
 LEFT JOIN customer_demographics cd ON a.demo_sk = cd.cd_demo_sk
),
ranked AS (
 SELECT
  dj.*,
  ROW_NUMBER() OVER (PARTITION BY dj.d_year, dj.cd_gender, dj.i_category ORDER BY dj.total_profit DESC) AS rn
 FROM demo_joined dj
)
SELECT
 r.d_year,
 r.cd_gender,
 r.i_category,
 r.i_class,
 r.customer_sk,
 c.c_first_name,
 c.c_last_name,
 r.cd_marital_status,
 r.cd_education_status,
 r.total_profit,
 r.transaction_count,
 r.avg_profit_per_txn
FROM ranked r
JOIN customer c ON r.customer_sk = c.c_customer_sk
WHERE r.rn <= 5
ORDER BY r.d_year, r.cd_gender, r.i_category, r.total_profit DESC
