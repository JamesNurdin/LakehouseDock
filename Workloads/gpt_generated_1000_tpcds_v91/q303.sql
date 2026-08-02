WITH sales_agg AS (
   SELECT
       cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_marital_status,
       SUM(cs.cs_net_profit) AS sum_net_profit,
       COUNT(*) AS sales_cnt,
       SUM(cs.cs_coupon_amt) AS total_coupon_amt
   FROM catalog_sales cs
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cs.cs_promo_sk = 1023
     AND cs.cs_coupon_amt > 0
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
     AND cd.cd_gender = 'M'
     AND cd.cd_marital_status IN ('M', 'S')
     AND cd.cd_dep_employed_count >= 1
   GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
returns_agg AS (
   SELECT
       cd.cd_demo_sk,
       SUM(sr.sr_net_loss) AS sum_net_loss,
       COUNT(*) AS returns_cnt
   FROM store_returns sr
   JOIN customer_demographics cd
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE sr.sr_fee > 10
     AND sr.sr_refunded_cash > 0
     AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
     AND cd.cd_gender = 'M'
     AND cd.cd_marital_status IN ('M', 'S')
   GROUP BY cd.cd_demo_sk
),
sales_without_returns AS (
   SELECT DISTINCT s.cd_demo_sk
   FROM sales_agg s
   WHERE NOT EXISTS (
       SELECT 1 FROM store_returns sr WHERE sr.sr_cdemo_sk = s.cd_demo_sk
   )
),
demo_keys_with_sales AS (
   SELECT DISTINCT cd_demo_sk FROM sales_agg
),
demo_keys_with_returns AS (
   SELECT DISTINCT cd_demo_sk FROM returns_agg
),
promo_demo_excluding_returns AS (
   SELECT cd_demo_sk FROM demo_keys_with_sales
   EXCEPT
   SELECT cd_demo_sk FROM demo_keys_with_returns
)
SELECT
   s.cd_demo_sk,
   s.cd_gender,
   s.cd_marital_status,
   s.sum_net_profit,
   s.sales_cnt,
   r.sum_net_loss,
   r.returns_cnt,
   SUM(s.sum_net_profit) OVER (PARTITION BY s.cd_gender) AS sum_profit_by_gender,
   RANK() OVER (ORDER BY s.sum_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cd_demo_sk = r.cd_demo_sk
WHERE s.cd_demo_sk IN (SELECT cd_demo_sk FROM promo_demo_excluding_returns)
  AND s.cd_demo_sk IN (SELECT cd_demo_sk FROM sales_without_returns)
ORDER BY s.sum_net_profit DESC
LIMIT 100
