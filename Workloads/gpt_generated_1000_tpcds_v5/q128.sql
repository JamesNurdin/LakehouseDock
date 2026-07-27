WITH promo_sales AS (
    SELECT p.p_promo_id,
           SUM(cs.cs_net_paid_inc_ship_tax) AS total_catalog_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
)
SELECT
    p.p_promo_id,
    'catalog' AS channel,
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship_tax AS sales_amount,
    cd.cd_credit_rating,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM promo_sales ps
        WHERE ps.p_promo_id = p.p_promo_id
          AND ps.total_catalog_sales > 50000
      )
  AND cd.cd_credit_rating = 'Good'
  AND ib.ib_lower_bound >= 50000

UNION ALL

SELECT
    p.p_promo_id,
    'web' AS channel,
    ws.ws_order_number,
    ws.ws_net_paid_inc_tax AS sales_amount,
    cd.cd_credit_rating,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM promo_sales ps
        WHERE ps.p_promo_id = p.p_promo_id
          AND ps.total_catalog_sales > 50000
      )
  AND cd.cd_credit_rating = 'Good'
  AND ib.ib_lower_bound >= 50000
LIMIT 100
