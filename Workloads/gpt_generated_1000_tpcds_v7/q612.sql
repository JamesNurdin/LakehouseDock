WITH filtered_sales AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk,
        ss.ss_item_sk,
        ss.ss_coupon_amt,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_item_sk IN (139967, 52041)
      AND ss.ss_coupon_amt > 20
)
SELECT
    p.p_promo_name,
    cd.cd_gender,
    t.t_meal_time,
    SUM(fs.ss_net_paid_inc_tax)               AS total_net_paid_inc_tax,
    AVG(fs.ss_coupon_amt)                     AS avg_coupon_amount,
    COUNT(*)                                   AS sales_transactions,
    CASE WHEN SUM(fs.ss_net_profit) > 5000
         THEN 'HIGH'
         ELSE 'LOW'
    END                                        AS profit_category
FROM filtered_sales fs
JOIN promotion p
  ON fs.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON fs.ss_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t
  ON fs.ss_sold_time_sk = t.t_time_sk
WHERE p.p_channel_catalog = 'N'
  AND p.p_channel_radio   = 'N'
  AND t.t_meal_time = 'lunch'
  AND t.t_second    = 0
GROUP BY p.p_promo_name, cd.cd_gender, t.t_meal_time
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
