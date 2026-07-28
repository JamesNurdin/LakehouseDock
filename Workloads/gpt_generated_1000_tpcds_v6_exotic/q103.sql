SELECT DISTINCT
    pr.p_promo_id,
    dd.d_date,
    pr.p_cost
FROM promotion pr
JOIN date_dim dd
  ON pr.p_start_date_sk = dd.d_date_sk
WHERE dd.d_dow = 2
  AND pr.p_channel_press = 'N'
LIMIT 100
