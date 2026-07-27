SELECT p.p_promo_id,
       p.p_cost,
       d.d_date,
       d.d_day_name
FROM promotion p
JOIN date_dim d
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_day_name = 'Monday'
  AND p.p_channel_demo = 'N'
ORDER BY p.p_cost DESC
