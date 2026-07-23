WITH avg_cost AS (
  SELECT AVG(p_cost) AS avg_cost FROM promotion
)
SELECT
  p.p_promo_id,
  start_d.d_date AS start_date,
  end_d.d_date AS end_date,
  p.p_cost,
  p.p_promo_name
FROM promotion p
JOIN date_dim start_d ON p.p_start_date_sk = start_d.d_date_sk
JOIN date_dim end_d ON p.p_end_date_sk = end_d.d_date_sk
WHERE start_d.d_following_holiday = 'Y'
  AND p.p_channel_email = 'Y'
  AND p.p_cost > (SELECT avg_cost FROM avg_cost)
UNION ALL
SELECT
  p2.p_promo_id,
  start_d2.d_date AS start_date,
  end_d2.d_date AS end_date,
  p2.p_cost,
  p2.p_promo_name
FROM promotion p2
JOIN date_dim start_d2 ON p2.p_start_date_sk = start_d2.d_date_sk
JOIN date_dim end_d2 ON p2.p_end_date_sk = end_d2.d_date_sk
WHERE end_d2.d_weekend = 'Y'
  AND p2.p_channel_radio = 'Y'
  AND EXISTS (
    SELECT 1 FROM promotion p3
    WHERE p3.p_item_sk = p2.p_item_sk
      AND p3.p_start_date_sk > p2.p_start_date_sk
  )
LIMIT 100
