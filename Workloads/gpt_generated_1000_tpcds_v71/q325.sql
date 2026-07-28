WITH
  customer_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address,
      c.c_login,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cr.cr_return_amount,
      cr.cr_net_loss,
      r.r_reason_desc,
      sm.sm_ship_mode_id,
      REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)\\s+return', 1) AS extracted_reason_word
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.+@example\\.com$')
      AND c.c_first_name LIKE 'J%'
      AND SUBSTRING(c.c_login, 1, 3) = 'usr'
  ),
  distinct_reason_words AS (
    SELECT DISTINCT extracted_reason_word
    FROM customer_returns
    WHERE extracted_reason_word IS NOT NULL
  )
SELECT
  CONCAT(cr.c_first_name, ' ', cr.c_last_name) AS full_name,
  cr.c_email_address,
  cr.ib_lower_bound,
  cr.ib_upper_bound,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  COUNT(DISTINCT cr.r_reason_desc) AS distinct_reason_cnt,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_promo_name LIKE '%Discount%'
        AND p.p_promo_id = 'PROMO123'
    ) THEN 'HasDiscountPromo'
    ELSE 'NoDiscountPromo'
  END AS promo_flag,
  (SELECT COUNT(*) FROM distinct_reason_words) AS total_distinct_reason_words
FROM customer_returns cr
GROUP BY GROUPING SETS (
  (cr.c_first_name, cr.c_last_name, cr.c_email_address, cr.ib_lower_bound, cr.ib_upper_bound),
  (cr.c_email_address, cr.ib_lower_bound, cr.ib_upper_bound),
  ()
)
ORDER BY total_net_loss DESC NULLS LAST, full_name
LIMIT 100
