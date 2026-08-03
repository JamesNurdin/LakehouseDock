SELECT
  sm.sm_carrier,
  SUM(cs.cs_ext_sales_price) AS total_sales
FROM tpcds.catalog_sales cs
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'FEDEX'
  AND cs.cs_ext_sales_price > 1000
GROUP BY sm.sm_carrier
ORDER BY total_sales DESC
