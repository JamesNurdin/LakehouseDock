WITH combined AS (
  SELECT
    promotion.p_promo_id AS promo_id,
    promotion.p_promo_sk AS promo_sk,
    time_dim.t_hour AS hour_of_day,
    'store' AS sales_channel,
    SUM(store_sales.ss_net_profit) AS net_profit,
    COUNT(*) AS txn_count
  FROM store_sales
  JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
  JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
  JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
  JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
  WHERE promotion.p_discount_active = 'Y'
    AND time_dim.t_hour BETWEEN 8 AND 20
    AND customer_demographics.cd_credit_rating = 'Good'
  GROUP BY promotion.p_promo_id, promotion.p_promo_sk, time_dim.t_hour

  UNION ALL

  SELECT
    promotion.p_promo_id AS promo_id,
    promotion.p_promo_sk AS promo_sk,
    time_dim.t_hour AS hour_of_day,
    'catalog' AS sales_channel,
    SUM(catalog_sales.cs_net_profit) AS net_profit,
    COUNT(*) AS txn_count
  FROM catalog_sales
  JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
  JOIN time_dim ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
  JOIN customer_demographics ON catalog_sales.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
  JOIN household_demographics ON catalog_sales.cs_bill_hdemo_sk = household_demographics.hd_demo_sk
  WHERE promotion.p_discount_active = 'Y'
    AND time_dim.t_hour BETWEEN 8 AND 20
    AND customer_demographics.cd_credit_rating = 'Good'
    AND EXISTS (
      SELECT 1
      FROM income_band ib
      WHERE ib.ib_income_band_sk = household_demographics.hd_income_band_sk
        AND ib.ib_lower_bound >= 50000
    )
  GROUP BY promotion.p_promo_id, promotion.p_promo_sk, time_dim.t_hour
)
SELECT
  promo_id,
  hour_of_day,
  sales_channel,
  net_profit,
  txn_count,
  (
    SELECT AVG(cs.cs_net_profit)
    FROM catalog_sales cs
    WHERE cs.cs_promo_sk = combined.promo_sk
  ) AS avg_catalog_net_profit
FROM combined
ORDER BY promo_id, hour_of_day, sales_channel
