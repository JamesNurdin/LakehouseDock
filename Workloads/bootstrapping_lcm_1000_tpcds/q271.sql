SELECT
  d_cc_closed.d_year AS year,
  d_cc_closed.d_month_seq AS month,
  cc.cc_division_name,
  s.s_division_name,
  COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
  COUNT(DISTINCT s.s_store_sk) AS num_stores,
  COUNT(DISTINCT p.p_promo_id) AS num_promotions,
  SUM(p.p_cost) AS total_promo_cost,
  AVG(p.p_cost) AS avg_promo_cost,
  SUM(p.p_cost) / NULLIF(AVG(cc.cc_sq_ft) + AVG(s.s_floor_space), 0) AS cost_per_sqft,
  COUNT(CASE WHEN d_promo_end.d_date_sk > d_cc_closed.d_date_sk THEN 1 END) AS ongoing_promos,
  CASE
    WHEN cc.cc_tax_percentage > 5 THEN 'HighTax'
    ELSE 'LowTax'
  END AS tax_category
FROM call_center cc
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE cc.cc_employees > 0
  AND s.s_number_employees > 0
GROUP BY
  d_cc_closed.d_year,
  d_cc_closed.d_month_seq,
  cc.cc_division_name,
  s.s_division_name,
  CASE
    WHEN cc.cc_tax_percentage > 5 THEN 'HighTax'
    ELSE 'LowTax'
  END
ORDER BY year DESC, month DESC
LIMIT 100
