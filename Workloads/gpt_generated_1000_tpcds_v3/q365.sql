WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_email_address,
           regexp_extract(c.c_email_address, '@([A-Za-z0-9.-]+)$', 1) AS email_domain,
           concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
)
SELECT s.s_store_id,
       concat(s.s_store_name, ' - ', s.s_city) AS store_full_name,
       fc.email_domain,
       COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
       SUM(ss.ss_net_profit) AS total_profit,
       AVG(ss.ss_quantity) AS avg_quantity
FROM tpcds.store_sales ss
JOIN filtered_customers fc ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_store_name LIKE '%Market%'
  AND s.s_rec_start_date >= DATE '2000-01-01'
GROUP BY s.s_store_id, s.s_store_name, s.s_city, fc.email_domain
HAVING SUM(ss.ss_net_profit) > 50000
ORDER BY total_profit DESC
LIMIT 100
