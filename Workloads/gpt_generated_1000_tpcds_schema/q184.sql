SELECT
  p.p_promo_id,
  p.p_promo_name,
  p.p_cost,
  p.p_response_target
FROM tpcds.promotion AS p
WHERE p.p_cost > 500.00
  AND p.p_channel_event = 'N'
ORDER BY p.p_cost DESC
LIMIT 10
