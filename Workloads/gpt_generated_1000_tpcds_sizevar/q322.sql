WITH cust_filtered AS (
   SELECT
     c_customer_sk,
     c_email_address,
     regexp_extract(c_email_address, '@([^.]*)\\.', 1) AS email_domain,
     LOWER(c_first_name) AS first_name_lc,
     CONCAT(c_first_name, ' ', c_last_name) AS full_name,
     c_preferred_cust_flag
   FROM tpcds.customer
   WHERE regexp_like(c_email_address, '^[A-Za-z0-9._%+-]+@.+\\.(com|net|org)$')
     AND c_first_name LIKE 'A%'
),
catalog_agg AS (
   SELECT
     cf.c_customer_sk,
     cf.email_domain,
     cf.c_preferred_cust_flag,
     SUM(cs.cs_net_paid) AS catalog_net_paid,
     SUM(cs.cs_net_profit) AS catalog_net_profit
   FROM cust_filtered cf
   JOIN tpcds.catalog_sales cs
     ON cs.cs_bill_customer_sk = cf.c_customer_sk
   GROUP BY cf.c_customer_sk, cf.email_domain, cf.c_preferred_cust_flag
),
web_agg AS (
   SELECT
     cf.c_customer_sk,
     cf.email_domain,
     cf.c_preferred_cust_flag,
     SUM(ws.ws_net_paid) AS web_net_paid,
     SUM(ws.ws_net_profit) AS web_net_profit
   FROM cust_filtered cf
   JOIN tpcds.web_sales ws
     ON ws.ws_bill_customer_sk = cf.c_customer_sk
   GROUP BY cf.c_customer_sk, cf.email_domain, cf.c_preferred_cust_flag
),
combined AS (
   SELECT
     COALESCE(ca.c_customer_sk, wa.c_customer_sk) AS c_customer_sk,
     COALESCE(ca.email_domain, wa.email_domain) AS email_domain,
     COALESCE(ca.c_preferred_cust_flag, wa.c_preferred_cust_flag) AS c_preferred_cust_flag,
     COALESCE(ca.catalog_net_paid, 0) + COALESCE(wa.web_net_paid, 0) AS total_net_paid,
     COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit
   FROM catalog_agg ca
   FULL OUTER JOIN web_agg wa
     ON ca.c_customer_sk = wa.c_customer_sk
        AND ca.email_domain = wa.email_domain
        AND ca.c_preferred_cust_flag = wa.c_preferred_cust_flag
)
SELECT
  COALESCE(combined.email_domain, 'ALL') AS email_domain,
  combined.c_preferred_cust_flag,
  combined.c_customer_sk,
  SUM(combined.total_net_paid) AS sum_net_paid,
  SUM(combined.total_net_profit) AS sum_net_profit,
  SUBSTRING(COALESCE(combined.email_domain, ''), 1, 3) AS domain_prefix
FROM combined
WHERE combined.total_net_paid > (
   SELECT AVG(cs.cs_net_paid) FROM tpcds.catalog_sales cs
)
GROUP BY ROLLUP (combined.email_domain, combined.c_preferred_cust_flag, combined.c_customer_sk)
ORDER BY
  CASE WHEN combined.email_domain IS NULL THEN 1 ELSE 0 END,
  email_domain,
  combined.c_preferred_cust_flag,
  combined.c_customer_sk
LIMIT 100
