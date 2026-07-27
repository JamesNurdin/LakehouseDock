SELECT DISTINCT cs.cs_order_number,
       sm.sm_carrier,
       cs.cs_sales_price
FROM tpcds.catalog_sales AS cs
JOIN tpcds.ship_mode AS sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'GREAT EASTERN'
  AND cs.cs_sales_price > 150
LIMIT 100
