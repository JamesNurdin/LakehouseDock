SELECT
  cc.cc_city,
  SUM(cr.cr_refunded_cash) AS total_refunded_cash,
  SUM(cr.cr_net_loss) AS total_net_loss
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cr.cr_refunded_cash > 100
  AND cr.cr_return_tax < 20
GROUP BY cc.cc_city
ORDER BY total_refunded_cash DESC
LIMIT 10
