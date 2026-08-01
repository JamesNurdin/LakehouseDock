SELECT hd.hd_buy_potential,
       hd.hd_vehicle_count,
       SUM(cr.cr_return_amount) AS total_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_return_amount > 1000
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY hd.hd_buy_potential, hd.hd_vehicle_count
ORDER BY total_return_amount DESC
LIMIT 100
