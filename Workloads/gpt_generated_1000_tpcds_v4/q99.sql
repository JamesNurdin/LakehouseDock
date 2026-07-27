SELECT
  cc.cc_name,
  i.i_brand,
  w.w_city,
  r.r_reason_desc,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_quantity) AS avg_return_quantity,
  COUNT(*) AS return_count,
  MIN(d.d_date) AS first_return_date,
  MAX(d.d_date) AS last_return_date
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 1905
  AND d.d_qoy = 2
  AND i.i_size = 'small'
  AND cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY cc.cc_name, i.i_brand, w.w_city, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
