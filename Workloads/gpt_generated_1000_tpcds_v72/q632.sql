SELECT DISTINCT
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    ss.ss_item_sk
FROM tpcds.store_sales AS ss
JOIN tpcds.household_demographics AS hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
  AND ss.ss_net_paid_inc_tax > 200
LIMIT 100
