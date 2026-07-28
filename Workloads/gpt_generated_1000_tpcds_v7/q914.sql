SELECT
  cc.cc_name,
  cp.cp_catalog_page_number,
  d.d_year,
  d.d_month_seq,
  COUNT(*) AS return_cnt,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_tax) AS avg_return_tax,
  MIN(cr.cr_return_amt_inc_tax) AS min_return_inc_tax,
  MAX(cr.cr_return_amt_inc_tax) AS max_return_inc_tax,
  SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_holiday = 'N'
  AND d.d_date = DATE '2002-03-15'
  AND cc.cc_state = 'CA'
  AND cc.cc_gmt_offset = -5.00
  AND cp.cp_catalog_number = 5
  AND cp.cp_type = 'C'
  AND cr.cr_return_quantity > 1
  AND cr.cr_return_tax > 5.00
GROUP BY
  cc.cc_name,
  cp.cp_catalog_page_number,
  d.d_year,
  d.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
