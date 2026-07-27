SELECT
  w.w_warehouse_name,
  cp.cp_department,
  p.p_promo_name,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(sr.sr_return_amt) AS total_return_amount,
  SUM(ss.ss_ext_discount_amt) AS total_discount,
  AVG(p.p_cost) AS avg_promo_cost,
  MIN(ss.ss_coupon_amt) AS min_coupon,
  MAX(ss.ss_coupon_amt) AS max_coupon
FROM store_sales ss
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_returning_customer_sk = c.c_customer_sk
  AND cr.cr_returning_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE ss.ss_coupon_amt > 100.00
  AND p.p_cost <= 2000.00
  AND w.w_county = 'Franklin Parish'
GROUP BY w.w_warehouse_name, cp.cp_department, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
