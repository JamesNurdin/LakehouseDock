SELECT
  w.w_city,
  w.w_warehouse_name,
  r.r_reason_desc,
  td.t_hour,
  i.i_category,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_amount) AS avg_return_amount,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  MIN(cr.cr_return_quantity) AS min_qty,
  MAX(cr.cr_return_quantity) AS max_qty
FROM catalog_returns cr
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
WHERE w.w_city = 'Pleasant Hill'
  AND w.w_warehouse_sq_ft > 500000
  AND w.w_warehouse_sq_ft = (
        SELECT MAX(w2.w_warehouse_sq_ft)
        FROM warehouse w2
        WHERE w2.w_city = w.w_city
      )
  AND r.r_reason_desc LIKE '%damaged%'
  AND td.t_hour BETWEEN 9 AND 17
  AND i.i_current_price > 50
  AND cr.cr_return_quantity > 0
  AND cr.cr_return_amount > 0
GROUP BY w.w_city, w.w_warehouse_name, r.r_reason_desc, td.t_hour, i.i_category
ORDER BY total_return_amount DESC
LIMIT 100
