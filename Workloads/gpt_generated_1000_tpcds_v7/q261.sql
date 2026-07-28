SELECT
    s.s_store_name,
    d.d_quarter_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
    MAX(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_name,
    COUNT(DISTINCT SUBSTR(ca.ca_zip, 1, 5)) AS distinct_zip_prefix,
    COUNT(DISTINCT REGEXP_EXTRACT(c.c_email_address, '@([^@]+)$', 1)) AS distinct_email_domains
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE p.p_promo_name LIKE '%Discount%'
  AND REGEXP_LIKE(c.c_email_address, '[A-Za-z0-9._%+-]+@[^@]+\\.com$')
  AND SUBSTR(ca.ca_zip, 1, 2) = '98'
GROUP BY s.s_store_name, d.d_quarter_name
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
