SELECT
  cc.cc_market_manager,
  s.s_state,
  p.p_promo_name,
  d_ret.d_year AS return_year,
  d_store.d_year AS store_close_year,
  d_cc_closed.d_year AS cc_closed_year,
  d_cc_open.d_year AS cc_open_year,
  d_promo_start.d_year AS promo_start_year,
  d_promo_end.d_year AS promo_end_year,
  CASE WHEN cc.cc_employees > 500 THEN 'Large' ELSE 'Small' END AS cc_size_category,
  (cc.cc_gmt_offset * s.s_gmt_offset) AS gmt_offset_product,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  AVG(cr.cr_return_quantity) AS avg_return_quantity,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  CASE
    WHEN SUM(cr.cr_return_amount) > 500000 THEN 'Very High'
    WHEN SUM(cr.cr_return_amount) > 100000 THEN 'High'
    ELSE 'Low'
  END AS return_category
FROM call_center cc
JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY
  cc.cc_market_manager,
  s.s_state,
  p.p_promo_name,
  d_ret.d_year,
  d_store.d_year,
  d_cc_closed.d_year,
  d_cc_open.d_year,
  d_promo_start.d_year,
  d_promo_end.d_year,
  CASE WHEN cc.cc_employees > 500 THEN 'Large' ELSE 'Small' END,
  (cc.cc_gmt_offset * s.s_gmt_offset)
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
