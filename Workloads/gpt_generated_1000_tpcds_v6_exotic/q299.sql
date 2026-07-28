WITH promo_sales AS (
   SELECT
       p.p_promo_id AS id,
       p.p_promo_name AS description,
       SUM(ws.ws_net_paid) AS total_amount,
       SUM(ws.ws_quantity) AS total_quantity,
       CONCAT('Domain:', regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_info,
       'promo_sales' AS source
   FROM web_sales ws
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE regexp_like(p.p_promo_name, '(?i)black.*friday')
     AND c.c_email_address LIKE '%@example.com'
   GROUP BY p.p_promo_id,
            p.p_promo_name,
            regexp_extract(c.c_email_address, '@(.+)$', 1)
),
catalog_ret AS (
   SELECT
       cp.cp_catalog_page_id AS id,
       cp.cp_description AS description,
       SUM(cr.cr_return_amount) AS total_amount,
       SUM(cr.cr_return_quantity) AS total_quantity,
       CONCAT('Domain:', regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_info,
       'catalog_returns' AS source
   FROM catalog_returns cr
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE regexp_like(cp.cp_description, '(?i)discount')
     AND c.c_email_address LIKE '%@example.org'
   GROUP BY cp.cp_catalog_page_id,
            cp.cp_description,
            regexp_extract(c.c_email_address, '@(.+)$', 1)
)
SELECT id,
       description,
       total_amount,
       total_quantity,
       email_info,
       source
FROM promo_sales
UNION ALL
SELECT id,
       description,
       total_amount,
       total_quantity,
       email_info,
       source
FROM catalog_ret
LIMIT 100
