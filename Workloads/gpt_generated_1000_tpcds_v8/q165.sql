SELECT
  w.w_warehouse_name,
  w.w_city,
  w.w_warehouse_sq_ft,
  SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
  SUM(cs.cs_net_paid_inc_ship) AS total_paid_inc_ship
FROM catalog_sales cs
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_promo_sk = 1212
  AND cs.cs_ext_ship_cost > 1000
GROUP BY
  w.w_warehouse_name,
  w.w_city,
  w.w_warehouse_sq_ft
ORDER BY total_ship_cost DESC
LIMIT 100
