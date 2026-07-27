SELECT
    hd.hd_vehicle_count,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.household_demographics hd
  ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_returning_hdemo_sk = 394
  AND cr.cr_return_amount > 0
  AND hd.hd_buy_potential = '>10000'
GROUP BY hd.hd_vehicle_count
ORDER BY total_return_amount DESC
