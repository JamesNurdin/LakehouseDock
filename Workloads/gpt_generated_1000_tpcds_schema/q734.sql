WITH email_domains AS (
   SELECT
       c.c_customer_sk,
       REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
   FROM tpcds.customer c
   WHERE REGEXP_LIKE(c.c_email_address, '^.*@.*\\.(com|org|net)$')
)
SELECT
   s.s_store_name,
   ed.email_domain,
   COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
   SUM(ss.ss_net_paid) AS total_net_paid,
   SUM(ss.ss_ext_tax) AS total_tax
FROM tpcds.store_sales ss
RIGHT OUTER JOIN tpcds.store s
   ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN email_domains ed
   ON ss.ss_customer_sk = ed.c_customer_sk
WHERE s.s_state LIKE 'A%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_promo_name LIKE '%discount%'
      )
GROUP BY GROUPING SETS (
    (s.s_store_name, ed.email_domain),
    (s.s_store_name),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
