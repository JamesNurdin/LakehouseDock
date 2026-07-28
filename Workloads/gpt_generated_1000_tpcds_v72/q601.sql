SELECT DISTINCT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    cs.cs_coupon_amt
FROM tpcds.catalog_sales cs
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_coupon_amt > 100.00
  AND cs.cs_sales_price < 50.00
ORDER BY sm.sm_carrier
