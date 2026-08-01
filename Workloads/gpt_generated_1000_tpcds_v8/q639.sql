SELECT
    pr.p_promo_id,
    pr.p_discount_active,
    dd.d_date AS start_date,
    dd.d_year,
    pr.p_cost
FROM promotion pr
JOIN date_dim dd
  ON pr.p_start_date_sk = dd.d_date_sk
WHERE pr.p_channel_dmail = 'Y'
  AND dd.d_fy_quarter_seq = 14
LIMIT 100
