WITH promo_gender_stats AS (
  SELECT
    p.p_promo_name AS promo_name,
    cd.cd_gender AS gender,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_net_paid) AS total_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
  FROM store_sales ss
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE cd.cd_purchase_estimate >= 1500
    AND cd.cd_credit_rating = 'Good'
    AND p.p_discount_active = 'Y'
    AND ss.ss_quantity > 0
  GROUP BY p.p_promo_name, cd.cd_gender
  HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
  promo_name,
  gender,
  total_profit,
  total_paid,
  avg_discount,
  distinct_customers,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM promo_gender_stats
ORDER BY total_profit DESC
LIMIT 10
