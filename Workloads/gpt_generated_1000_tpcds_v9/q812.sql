WITH combined_sales AS (
    SELECT c.c_customer_sk,
           c.c_email_address,
           ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
      AND d.d_current_year = 'Y'
      AND c.c_email_address LIKE '%@gmail.com'
      AND regexp_like(c.c_email_address, '^[a-z0-9._%+-]+@gmail\\.com$')
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_email_address,
           ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
      AND d.d_current_year = 'Y'
      AND c.c_email_address LIKE '%@gmail.com'
      AND regexp_like(c.c_email_address, '^[a-z0-9._%+-]+@gmail\\.com$')
)
SELECT regexp_extract(c_email_address, '@(.*)$', 1) AS email_domain,
       COUNT(DISTINCT c_customer_sk) AS num_customers,
       SUM(net_paid) AS total_net_paid,
       AVG(net_paid) AS avg_net_paid,
       MIN(substr(c_email_address, 1, strpos(c_email_address, '@') - 1)) AS sample_user_prefix
FROM combined_sales
GROUP BY regexp_extract(c_email_address, '@(.*)$', 1)
ORDER BY total_net_paid DESC
LIMIT 100
