SELECT
    sm1.sm_carrier AS carrier,
    cd_bill.cd_credit_rating AS credit_rating,
    p_cat1.p_promo_name AS catalog_promo_name,
    p_store.p_promo_name AS store_promo_name,
    sm2.sm_contract AS contract,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price)) AS total_sales,
    CASE WHEN SUM(cs.cs_net_profit) > SUM(ss.ss_net_profit) THEN 'Catalog' ELSE 'Store' END AS higher_profit_channel,
    CASE
        WHEN cd_bill.cd_credit_rating = 'Good' THEN 'Low Risk'
        WHEN cd_bill.cd_credit_rating = 'High Risk' THEN 'High Risk'
        ELSE 'Other'
    END AS credit_risk_category
FROM catalog_sales cs
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm1
    ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN ship_mode sm2
    ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN promotion p_cat1
    ON cs.cs_promo_sk = p_cat1.p_promo_sk
JOIN promotion p_cat2
    ON cs.cs_promo_sk = p_cat2.p_promo_sk
JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
JOIN promotion p_store
    ON ss.ss_promo_sk = p_store.p_promo_sk
JOIN customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
WHERE sm1.sm_contract IN ('A5BYO1qH8HGTTN', 'OrDuVy2H')
  AND cd_bill.cd_dep_count >= 3
  AND EXISTS (
      SELECT 1
      FROM promotion p_sub
      WHERE p_sub.p_promo_sk = cs.cs_promo_sk
        AND p_sub.p_discount_active = 'Y'
  )
GROUP BY
    sm1.sm_carrier,
    cd_bill.cd_credit_rating,
    p_cat1.p_promo_name,
    p_store.p_promo_name,
    sm2.sm_contract
ORDER BY total_sales DESC
LIMIT 100
