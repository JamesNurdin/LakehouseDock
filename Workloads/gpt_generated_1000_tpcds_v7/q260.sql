SELECT
  cp.cp_catalog_page_id,
  REGEXP_EXTRACT(cp.cp_description, '^(.{0,30})') AS short_description,
  COUNT(DISTINCT cr.cr_order_number) AS return_orders,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  ARRAY_AGG(DISTINCT r.r_reason_desc) AS reason_list
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_address ca
  ON cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN date_dim dd
  ON cr.cr_returned_date_sk = dd.d_date_sk
WHERE REGEXP_LIKE(cp.cp_description, '(?i)fashion|electronics')
  AND ca.ca_city LIKE '%York%'
  AND REGEXP_EXTRACT(ca.ca_address_id, '(A{5,})') IS NOT NULL
  AND dd.d_year = 2001
GROUP BY cp.cp_catalog_page_id, cp.cp_description
ORDER BY total_return_amount DESC
LIMIT 10
