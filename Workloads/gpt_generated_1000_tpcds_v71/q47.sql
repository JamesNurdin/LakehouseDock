SELECT
    cs.cs_order_number,
    cs.cs_sales_price,
    cs.cs_ext_ship_cost,
    sm.sm_ship_mode_id,
    sm.sm_type
FROM tpcds.catalog_sales AS cs
JOIN tpcds.ship_mode AS sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sales_price > 20.00
  AND sm.sm_code = 'AIR'
ORDER BY cs.cs_sales_price DESC
LIMIT 100
