SELECT
    c.c_birth_country,
    SUM(ss.ss_net_paid_inc_tax) AS total_spent,
    COUNT(*) AS purchase_count
FROM tpcds.customer c
JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'CHILE'
  AND ss.ss_net_profit > 0
  AND ss.ss_net_paid_inc_tax > 500
GROUP BY c.c_birth_country
