SELECT DISTINCT cr.cr_return_amount,
       cr.cr_return_quantity,
       hd.hd_buy_potential,
       hd.hd_dep_count
FROM catalog_returns cr
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_ship_mode_sk = 5
  AND cr.cr_reversed_charge > 150.00
  AND hd.hd_buy_potential = '501-1000'
ORDER BY cr.cr_return_amount DESC
LIMIT 100
