SELECT
    w.w_warehouse_name,
    d.d_week_seq,
    cp.cp_type,
    MAX(REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1)) AS first_word_desc,
    MAX(CONCAT(w.w_warehouse_name, '-', ca_refunded.ca_city)) AS warehouse_city_key,
    COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
WHERE REGEXP_LIKE(cp.cp_description, 'Special|Promo')
  AND cr.cr_warehouse_sk IN (
      SELECT w2.w_warehouse_sk FROM warehouse w2 WHERE w2.w_city LIKE 'San%'
  )
GROUP BY CUBE (w.w_warehouse_name, d.d_week_seq, cp.cp_type)
ORDER BY total_return_amount DESC
LIMIT 100
