WITH group_metrics AS (
   SELECT
     cd.cd_gender,
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     SUM(ss.ss_net_profit) AS total_profit,
     AVG(ss.ss_sales_price) AS avg_sales_price,
     COUNT(*) AS transaction_cnt
   FROM store_sales ss
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE c.c_salutation = 'Mrs.'
     AND cd.cd_credit_rating = 'Low Risk'
     AND ib.ib_lower_bound >= 50000
     AND ss.ss_sales_price > 0
     AND c.c_current_cdemo_sk = cd.cd_demo_sk
     AND c.c_current_hdemo_sk = hd.hd_demo_sk
   GROUP BY cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
   HAVING SUM(ss.ss_net_profit) > 5000
),
top_groups AS (
   SELECT *
   FROM group_metrics
   WHERE transaction_cnt >= 10
   ORDER BY total_profit DESC
   LIMIT 100
)
SELECT
   COUNT(*) AS top_group_count,
   AVG(total_profit) AS avg_top_profit,
   MAX(avg_sales_price) AS max_avg_price
FROM top_groups
WHERE avg_sales_price > 15
HAVING AVG(total_profit) > 2000
LIMIT 100
