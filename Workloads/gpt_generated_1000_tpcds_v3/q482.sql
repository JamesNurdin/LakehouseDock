SELECT DISTINCT cs.cs_order_number, cs.cs_net_paid_inc_ship_tax, hd.hd_buy_potential
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
WHERE cs.cs_coupon_amt >= 501.49
  AND hd.hd_dep_count = 0
LIMIT 100
