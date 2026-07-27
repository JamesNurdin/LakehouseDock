WITH high_value_customers AS (
    SELECT cd.cd_demo_sk
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate >= 8000
      AND cd.cd_credit_rating = 'Low Risk'
)
SELECT
    ss.ss_store_sk AS store_sk,
    ss.ss_promo_sk AS promo_sk,
    SUM(ss.ss_net_profit) AS profit,
    COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential = '>10000'
  AND EXISTS (
        SELECT 1
        FROM high_value_customers hvc
        WHERE hvc.cd_demo_sk = ss.ss_cdemo_sk
      )
GROUP BY ss.ss_store_sk, ss.ss_promo_sk
HAVING SUM(ss.ss_net_profit) > 10000

UNION ALL

SELECT
    ss2.ss_store_sk AS store_sk,
    ss2.ss_promo_sk AS promo_sk,
    SUM(ss2.ss_net_profit) AS profit,
    COUNT(*) AS sales_cnt
FROM store_sales ss2
JOIN customer_demographics cd2 ON ss2.ss_cdemo_sk = cd2.cd_demo_sk
WHERE cd2.cd_credit_rating = 'High Risk'
  AND cd2.cd_purchase_estimate < 5000
GROUP BY ss2.ss_store_sk, ss2.ss_promo_sk
HAVING COUNT(*) >= 20

ORDER BY profit DESC
LIMIT 100
