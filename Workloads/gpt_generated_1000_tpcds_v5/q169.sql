WITH base AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_net_paid_inc_tax,
    ss.ss_net_profit,
    cr.cr_return_amount,
    cr.cr_net_loss,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
      WHEN ib.ib_upper_bound > 100000 THEN 'HighIncome'
      WHEN ib.ib_upper_bound BETWEEN 50000 AND 100000 THEN 'MidIncome'
      ELSE 'LowIncome'
    END AS income_category
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
       AND cr.cr_return_amount > 0
)
SELECT
  income_category,
  ib_lower_bound,
  ib_upper_bound,
  COUNT(DISTINCT ss_ticket_number) AS distinct_sales,
  SUM(ss_net_profit) AS total_net_profit,
  SUM(cr_net_loss) AS total_net_loss,
  SUM(ss_net_profit) - SUM(cr_net_loss) AS net_contribution,
  CASE
    WHEN SUM(ss_net_profit) > 0 AND SUM(cr_net_loss) > 0 THEN 'BothPositive'
    WHEN SUM(ss_net_profit) > 0 THEN 'ProfitOnly'
    WHEN SUM(cr_net_loss) > 0 THEN 'LossOnly'
    ELSE 'Neutral'
  END AS performance_flag,
  RANK() OVER (ORDER BY (SUM(ss_net_profit) - SUM(cr_net_loss)) DESC) AS profit_loss_rank,
  (SELECT AVG(cr_net_loss) FROM catalog_returns) AS avg_return_loss
FROM base
WHERE ss_net_paid_inc_tax > 1000
  AND ss_net_profit BETWEEN -5000 AND 5000
  AND cr_return_amount IS NOT NULL
  AND ib_lower_bound >= 10000
  AND ib_upper_bound <= 200000
GROUP BY income_category, ib_lower_bound, ib_upper_bound
HAVING COUNT(DISTINCT ss_ticket_number) >= 10
ORDER BY profit_loss_rank
LIMIT 100
