SELECT
  cr.cr_return_amount,
  cr.cr_return_tax,
  cr.cr_fee,
  cr.cr_return_quantity,
  cr.cr_return_ship_cost,
  cc.cc_state,
  cc.cc_gmt_offset,
  (cr.cr_return_amount * (1 + cr.cr_return_tax)) AS total_return_with_tax,
  (cr.cr_return_amount - cr.cr_fee - cr.cr_return_ship_cost) AS net_return,
  CASE WHEN cr.cr_return_amount > 403.08 THEN 'High' ELSE 'Low' END AS amount_category,
  CASE WHEN cc.cc_state = 'FL' THEN 'Local' ELSE 'Other' END AS state_category,
  CASE WHEN cc.cc_gmt_offset >= -5.00 THEN 'East' ELSE 'West' END AS gmt_offset_region
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cr.cr_returned_date_sk = 2451179 AND cc.cc_country = 'United States'
