WITH
  sales_keys AS (
    SELECT ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    EXCEPT
    SELECT sr.sr_ticket_number
    FROM store_returns sr
  ),
  catalog_keys AS (
    SELECT cs.cs_order_number AS ticket_number
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
  ),
  combined_keys AS (
    SELECT ticket_number FROM sales_keys
    UNION
    SELECT ticket_number FROM catalog_keys
  )
SELECT
  CONCAT(s.s_store_name, ' - ', CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END) AS location_promo,
  CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
  MIN(REGEXP_EXTRACT(i.i_product_name, '^(\\w+)', 1)) AS product_first_word,
  SUM(ss.ss_net_paid) AS total_net_paid,
  COUNT(DISTINCT ss.ss_ticket_number) AS orders_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN combined_keys ck ON ss.ss_ticket_number = ck.ticket_number
WHERE REGEXP_LIKE(i.i_product_name, '(?i)premium')
  AND s.s_store_name LIKE '%Store%'
GROUP BY s.s_store_name, p.p_discount_active

UNION

SELECT
  CONCAT(cp.cp_department, ' - ', CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END) AS location_promo,
  CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
  MIN(REGEXP_EXTRACT(i.i_product_name, '^(\\w+)', 1)) AS product_first_word,
  SUM(cs.cs_net_paid) AS total_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN combined_keys ck ON cs.cs_order_number = ck.ticket_number
WHERE REGEXP_LIKE(i.i_product_name, '(?i)premium')
  AND cp.cp_department LIKE 'Electronics%'
GROUP BY cp.cp_department, p.p_discount_active

ORDER BY total_net_paid DESC
LIMIT 100
