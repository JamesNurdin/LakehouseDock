WITH filtered_customers AS (
   SELECT c.c_customer_sk,
          c.c_customer_id,
          c.c_email_address,
          regexp_extract(c.c_email_address, '@([A-Za-z0-9.-]+\\.com)$', 1) AS email_domain,
          concat(substr(c.c_first_name, 1, 1), substr(c.c_last_name, 1, 1)) AS initials
   FROM tpcds.customer c
   WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.com$')
     AND c.c_preferred_cust_flag = 'Y'
     AND c.c_first_name LIKE 'A%'
),

sales_union AS (
   SELECT ss.ss_customer_sk AS cust_sk,
          ss.ss_net_paid AS net_paid,
          d.d_year
   FROM tpcds.store_sales ss
   JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION ALL
   SELECT cs.cs_bill_customer_sk AS cust_sk,
          cs.cs_net_paid AS net_paid,
          d.d_year
   FROM tpcds.catalog_sales cs
   JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION ALL
   SELECT ws.ws_bill_customer_sk AS cust_sk,
          ws.ws_net_paid AS net_paid,
          d.d_year
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)

SELECT fc.c_customer_id,
       fc.email_domain,
       fc.initials,
       COUNT(*) AS purchase_count,
       SUM(su.net_paid) AS total_spent
FROM filtered_customers fc
JOIN sales_union su ON fc.c_customer_sk = su.cust_sk
GROUP BY fc.c_customer_id, fc.email_domain, fc.initials
ORDER BY total_spent DESC
LIMIT 100
