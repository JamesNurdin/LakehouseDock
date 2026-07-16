WITH sales_monthly AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    date_trunc('month', from_unixtime(ss.ss_sold_date_sk * 86400)) AS month,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
    AVG(2026 - c.c_birth_year) AS avg_customer_age,
    SUM(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_high_buy_potential
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450821 AND 2452168
    AND c.c_birth_year BETWEEN 1950 AND 1990
  GROUP BY ss.ss_store_sk, date_trunc('month', from_unixtime(ss.ss_sold_date_sk * 86400))
),
returns_monthly AS (
  SELECT
    sr.sr_store_sk AS store_sk,
    date_trunc('month', from_unixtime(sr.sr_returned_date_sk * 86400)) AS month,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_txn_cnt
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk BETWEEN 2450821 AND 2452168
  GROUP BY sr.sr_store_sk, date_trunc('month', from_unixtime(sr.sr_returned_date_sk * 86400))
)
SELECT
  s.s_store_name,
  s.s_city,
  sm.month,
  sm.total_sales_amount,
  sm.total_net_profit,
  COALESCE(rm.total_net_loss, 0) AS total_net_loss,
  sm.total_net_profit - COALESCE(rm.total_net_loss, 0) AS net_profit_after_returns,
  sm.sales_txn_cnt,
  COALESCE(rm.return_txn_cnt, 0) AS return_txn_cnt,
  ROUND(sm.avg_customer_age, 1) AS avg_customer_age,
  ROUND(sm.pct_high_buy_potential, 2) AS pct_high_buy_potential
FROM sales_monthly sm
LEFT JOIN returns_monthly rm
  ON sm.store_sk = rm.store_sk
  AND sm.month = rm.month
JOIN store s ON sm.store_sk = s.s_store_sk
WHERE s.s_country = 'United States'
ORDER BY s.s_store_name, sm.month
