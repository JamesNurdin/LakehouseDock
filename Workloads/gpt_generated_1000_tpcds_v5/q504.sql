WITH cust_email AS (
    SELECT
        c_customer_sk,
        c_email_address,
        regexp_extract(c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        CASE WHEN regexp_like(c_login, '^a[0-9]{2,}$') THEN 1 ELSE 0 END AS login_a_digit_flag,
        c_first_name,
        c_last_name
    FROM tpcds.customer
    WHERE c_email_address LIKE '%@%.com'
      AND regexp_like(c_login, '^[a-z]{3,}$')
)
SELECT
    ce.email_domain,
    ss.ss_store_sk,
    COUNT(DISTINCT ce.c_customer_sk) AS unique_customers,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_tax) AS avg_tax,
    SUM(CASE WHEN ce.login_a_digit_flag = 1 THEN ss.ss_net_paid ELSE 0 END) AS net_paid_login_a_digit
FROM cust_email ce
JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = ce.c_customer_sk
WHERE ss.ss_ext_tax > 10.00
GROUP BY ce.email_domain, ss.ss_store_sk
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
