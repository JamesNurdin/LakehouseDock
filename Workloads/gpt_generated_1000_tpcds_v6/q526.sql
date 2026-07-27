WITH overall AS (
    SELECT avg(cr_return_amount) AS overall_avg
    FROM catalog_returns
)
SELECT
    d.d_year,
    hd_ref.hd_buy_potential,
    wp.wp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MAX(cr.cr_return_amount) AS max_return_amount,
    (SELECT overall_avg FROM overall) AS overall_avg_return_amount
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c_ref
  ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer c_ret
  ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c_ret.c_customer_sk
 AND wp.wp_creation_date_sk = d.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND hd_ref.hd_income_band_sk IN (11, 16, 20)
  AND hd_ref.hd_vehicle_count >= 2
  AND c_ref.c_birth_country = 'United States'
  AND p.p_discount_active = 'Y'
  AND wp.wp_type = 'product'
  AND cr.cr_return_amount > 10.00
GROUP BY d.d_year, hd_ref.hd_buy_potential, wp.wp_type
ORDER BY total_return_amount DESC
LIMIT 100
