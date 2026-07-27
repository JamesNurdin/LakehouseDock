/*
  Goal: For each store and its associated call center (both closed in the same year), compute the total promotion cost of promotions that started and ended on that closing date, count promotions, flag if any promotion had an active discount, and rank stores within each state by total promotion cost.
*/
WITH joined_data AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_state,
    p.p_cost,
    p.p_discount_active,
    d.d_year
  FROM store s
  JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
  JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
   AND p.p_end_date_sk   = d.d_date_sk
  WHERE d.d_year = 2000
    AND s.s_state = 'CA'
    AND cc.cc_state = 'CA'
    AND p.p_purpose = 'Unknown'
    AND p.p_channel_press = 'N'
)
SELECT
  s_store_id,
  s_store_name,
  s_state,
  cc_call_center_id,
  cc_state,
  SUM(p_cost) AS total_promo_cost,
  COUNT(*)    AS promo_count,
  CASE WHEN SUM(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) > 0
       THEN 'Yes' ELSE 'No' END AS any_discount_active,
  RANK() OVER (PARTITION BY s_state ORDER BY SUM(p_cost) DESC) AS state_store_rank
FROM joined_data
GROUP BY
  s_store_id,
  s_store_name,
  s_state,
  cc_call_center_id,
  cc_state
ORDER BY
  s_state,
  state_store_rank
