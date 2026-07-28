SELECT
    p.p_promo_id,
    p.p_discount_active,
    d.d_year,
    d.d_month_seq,
    COUNT(*) AS promo_cnt
FROM promotion p
JOIN date_dim d
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 1917
  AND p.p_start_date_sk = 2450360
GROUP BY p.p_promo_id, p.p_discount_active, d.d_year, d.d_month_seq
ORDER BY promo_cnt DESC
LIMIT 10
