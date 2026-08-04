SELECT cc.cc_name,
       sum(cr.cr_return_amount) AS total_return_amount,
       count(*) AS return_count
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_rec_end_date = DATE '2001-12-31'
  AND cc.cc_company = 3
  AND cr.cr_ship_mode_sk = 5
  AND cr.cr_return_ship_cost > 100.00
GROUP BY cc.cc_name
ORDER BY total_return_amount DESC
LIMIT 10
