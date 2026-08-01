WITH customer_sales AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 100
      AND ss.ss_ext_discount_amt < 2000
      AND ss.ss_quantity >= 1
    GROUP BY ss.ss_customer_sk
)
SELECT
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(cs.total_sales) AS state_total_sales,
    AVG(cs.total_discount) AS avg_discount_per_customer,
    SUM(cs.total_profit) AS state_total_profit
FROM customer_sales cs
JOIN customer c
    ON cs.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_day = 2
  AND c.c_birth_month = 5
  AND ca.ca_suite_number = 'Suite 280'
  AND ca.ca_state IN ('CA', 'TX', 'NY')
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.ss_customer_sk
          AND ss2.ss_ext_sales_price > 2000
        LIMIT 1
    )
GROUP BY ca.ca_state
HAVING SUM(cs.total_profit) > 5000
   AND COUNT(DISTINCT c.c_customer_sk) >= 10
ORDER BY state_total_sales DESC
LIMIT 100
