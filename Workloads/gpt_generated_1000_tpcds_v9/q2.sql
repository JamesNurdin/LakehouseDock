SELECT
    ss_store_sk,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    SUM(ss_net_paid) AS total_net_paid
FROM store_sales
WHERE ss_store_sk = 847
  AND ss_coupon_amt > 1000
GROUP BY ss_store_sk
ORDER BY distinct_customers DESC
LIMIT 100
