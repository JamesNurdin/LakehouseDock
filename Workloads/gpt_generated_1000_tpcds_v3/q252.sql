SELECT
  w.w_warehouse_id,
  w.w_warehouse_name,
  d.d_year,
  d.d_month_seq,
  t.t_hour,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_order_count,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_ticket_count,
  SUM(cr.cr_net_loss) AS total_catalog_net_loss,
  SUM(sr.sr_net_loss) AS total_store_net_loss,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  AVG(cr.cr_return_tax) AS avg_catalog_return_tax,
  AVG(sr.sr_return_tax) AS avg_store_return_tax,
  (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS total_net_loss
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  AND sr.sr_return_time_sk = t.t_time_sk
  AND sr.sr_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND w.w_city = 'San Francisco'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year, d.d_month_seq, t.t_hour
ORDER BY total_net_loss DESC, w.w_warehouse_name ASC
LIMIT 100
