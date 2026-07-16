SELECT cc.cc_name AS call_center,
       d_ret.d_month_seq AS month,
       r.r_reason_desc AS return_reason,
       sm.sm_type AS shipping_type,
       COUNT(*) AS total_returns,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d_ret.d_year = 2001
  AND i.i_current_price > 100
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'Return'
GROUP BY cc.cc_name, d_ret.d_month_seq, r.r_reason_desc, sm.sm_type
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
