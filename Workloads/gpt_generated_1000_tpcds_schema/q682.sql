WITH eligible_customers AS (
       SELECT c.c_customer_sk
       FROM tpcds.customer c
       WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
       INTERSECT
       SELECT c.c_customer_sk
       FROM tpcds.customer c
       WHERE c.c_birth_country LIKE 'U%'
   ),
   high_income_not_ca AS (
       SELECT c.c_customer_sk
       FROM tpcds.customer c
       JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
       JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
       WHERE ib.ib_upper_bound > 50000
       EXCEPT
       SELECT c.c_customer_sk
       FROM tpcds.customer c
       JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
       WHERE ca.ca_state = 'CA'
   ),
   cust_return_stats AS (
       SELECT
           c.c_customer_sk,
           c.c_email_address,
           ca.ca_state,
           ib.ib_upper_bound,
           c.c_first_name,
           c.c_last_name,
           c.c_first_name || ' ' || c.c_last_name AS full_name,
           regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_prefix,
           regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt,
           CASE
               WHEN SUM(sr.sr_return_amt) < 100 THEN 'Low'
               WHEN SUM(sr.sr_return_amt) BETWEEN 100 AND 500 THEN 'Medium'
               ELSE 'High'
           END AS return_level,
           MAX(CASE WHEN regexp_like(r.r_reason_desc, '(?i)warranty') THEN 1 ELSE 0 END) AS warranty_flag
       FROM tpcds.store_returns sr
       JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
       JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
       JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
       JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
       JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
       WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
         AND c.c_birth_country LIKE 'U%'
       GROUP BY
           c.c_customer_sk,
           c.c_email_address,
           ca.ca_state,
           ib.ib_upper_bound,
           c.c_first_name,
           c.c_last_name
   )
SELECT
    crs.c_customer_sk,
    crs.full_name,
    crs.c_email_address,
    crs.email_prefix,
    crs.email_domain,
    crs.ca_state,
    crs.total_return_amt,
    crs.return_cnt,
    crs.return_level,
    crs.warranty_flag
FROM cust_return_stats crs
WHERE crs.c_customer_sk IN (SELECT c_customer_sk FROM eligible_customers)

UNION DISTINCT

SELECT
    c.c_customer_sk,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.c_email_address,
    regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_prefix,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    ca.ca_state,
    CAST(0.0 AS decimal(7,2)) AS total_return_amt,
    CAST(0 AS integer) AS return_cnt,
    'NoReturn' AS return_level,
    CAST(0 AS integer) AS warranty_flag
FROM tpcds.customer c
JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM high_income_not_ca)

ORDER BY total_return_amt DESC, c_customer_sk
