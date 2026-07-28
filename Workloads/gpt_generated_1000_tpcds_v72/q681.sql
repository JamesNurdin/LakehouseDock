SELECT DISTINCT
  cc.cc_name,
  cc.cc_city,
  cr.cr_return_amount
FROM tpcds.call_center AS cc
JOIN tpcds.catalog_returns AS cr
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_class = 'large'
  AND cr.cr_refunded_hdemo_sk = 5112
ORDER BY cr.cr_return_amount DESC
