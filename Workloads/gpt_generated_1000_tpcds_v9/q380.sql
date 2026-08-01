SELECT cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_fee,
       hd.hd_vehicle_count,
       hd.hd_buy_potential
FROM catalog_returns cr
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential = '1001-5000      '
  AND cr.cr_fee > 50
ORDER BY cr.cr_return_amount DESC
LIMIT 100
