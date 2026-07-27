SELECT
  cc.cc_name,
  cc.cc_city,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_company = 5
  AND cr.cr_store_credit > 500
GROUP BY cc.cc_name, cc.cc_city
ORDER BY total_return_amount DESC
