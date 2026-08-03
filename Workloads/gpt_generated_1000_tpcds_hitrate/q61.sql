WITH min_korea_birth_year AS (
    SELECT MIN(c_birth_year) AS min_year
    FROM tpcds.customer
    WHERE c_birth_country = 'KOREA'
)
SELECT
    cc.cc_name,
    c1.c_birth_country,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_quantity) AS avg_quantity
FROM tpcds.store_sales ss
JOIN tpcds.customer c1
    ON ss.ss_customer_sk = c1.c_customer_sk
JOIN tpcds.customer_address ca1
    ON ss.ss_addr_sk = ca1.ca_address_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.customer c2
    ON sr.sr_customer_sk = c2.c_customer_sk
JOIN tpcds.customer_address ca2
    ON sr.sr_addr_sk = ca2.ca_address_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_refunded_customer_sk = c2.c_customer_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c1.c_customer_sk
WHERE c1.c_birth_year > (SELECT min_year FROM min_korea_birth_year)
GROUP BY cc.cc_name, c1.c_birth_country
ORDER BY total_store_net_loss DESC
LIMIT 100
