WITH base AS (
  SELECT
    i.i_item_id,
    sm.sm_type,
    td.t_hour,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(cr.cr_return_quantity) AS sum_quantity,
    AVG(cr.cr_return_tax) AS avg_return_tax
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  WHERE cr.cr_return_amount > 100
    AND cr.cr_return_quantity > 0
    AND i.i_current_price BETWEEN 10 AND 1000
    AND sm.sm_type = 'REGULAR'
    AND cr.cr_return_amount > (
      SELECT MAX(p_cost) FROM promotion WHERE p_promo_id = 'PROMO_001'
    )
  GROUP BY i.i_item_id, sm.sm_type, td.t_hour
)
SELECT
  u.i_item_id,
  AVG(u.sum_return_amount) AS avg_sum_return_amount,
  SUM(u.sum_quantity) AS total_quantity
FROM (
  SELECT i_item_id, sm_type, t_hour, sum_return_amount, sum_quantity, avg_return_tax
  FROM base
  WHERE sum_quantity > 5
  UNION DISTINCT
  SELECT i_item_id, sm_type, t_hour, sum_return_amount, sum_quantity, avg_return_tax
  FROM base
  WHERE avg_return_tax < 5
) u
GROUP BY u.i_item_id
HAVING AVG(u.sum_return_amount) > 200
ORDER BY avg_sum_return_amount DESC
LIMIT 100
