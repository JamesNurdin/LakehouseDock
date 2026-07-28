SELECT
   d.d_year AS year,
   w.w_warehouse_name,
   COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
   SUM(cr.cr_net_loss) AS total_net_loss,
   MAX(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND w.w_warehouse_name LIKE '%Distribution%'
  AND substr(c.c_first_name, 1, 1) = 'J'
GROUP BY d.d_year, w.w_warehouse_name
ORDER BY total_net_loss DESC
LIMIT 10
