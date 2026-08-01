SELECT DISTINCT
    p.p_promo_id,
    p.p_promo_name,
    p.p_start_date_sk,
    p.p_end_date_sk,
    p.p_discount_active
FROM tpcds.promotion AS p
WHERE p.p_end_date_sk >= 2450350
  AND p.p_end_date_sk <= 2450700
  AND p.p_discount_active = 'Y'
ORDER BY p.p_end_date_sk DESC
LIMIT 100
