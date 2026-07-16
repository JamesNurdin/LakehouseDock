SELECT
  d.d_year,
  d.d_month_seq,
  w.w_warehouse_name,
  w.w_city AS warehouse_city,
  w.w_state AS warehouse_state,
  s.s_store_name,
  s.s_city AS store_city,
  s.s_state AS store_state,
  cc.cc_name,
  cc.cc_city,
  cc.cc_state,
  SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
  AVG(w.w_warehouse_sq_ft) AS avg_warehouse_sq_ft,
  AVG(s.s_floor_space) AS avg_store_floor_space,
  AVG(cc.cc_tax_percentage) AS avg_call_center_tax,
  MAX(d.d_date) AS max_date,
  MIN(d.d_date) AS min_date
FROM inventory i
JOIN date_dim d
  ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2025
  AND i.inv_quantity_on_hand > 0
GROUP BY
  d.d_year,
  d.d_month_seq,
  w.w_warehouse_name,
  w.w_city,
  w.w_state,
  s.s_store_name,
  s.s_city,
  s.s_state,
  cc.cc_name,
  cc.cc_city,
  cc.cc_state
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY d.d_year, d.d_month_seq, total_quantity_on_hand DESC
LIMIT 100
