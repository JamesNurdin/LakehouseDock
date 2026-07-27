WITH filtered_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1950 AND 1965
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_last_review_date > 2452000
      AND c.c_first_shipto_date_sk >= 2450000
      AND c.c_login IS NOT NULL
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_ship_mode_id,
    r.r_reason_desc,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'No Loss' END AS loss_flag,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank,
    COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS sales_order_cnt
FROM catalog_returns cr
JOIN customer c_refunded
  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN household_demographics hd_refunded
  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib
  ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c_refunded.c_customer_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE ib.ib_lower_bound >= 30000
  AND ib.ib_upper_bound <= 120000
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc LIKE '%defect%'
  AND cr.cr_return_quantity > 1
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c_refunded.c_customer_sk
          AND ws2.ws_promo_sk = p.p_promo_sk
          AND ws2.ws_quantity > 5
    )
  AND c_refunded.c_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, sm.sm_ship_mode_id, r.r_reason_desc
ORDER BY total_return_loss DESC
LIMIT 100
