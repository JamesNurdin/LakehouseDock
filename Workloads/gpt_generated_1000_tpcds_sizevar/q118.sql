WITH filtered_customers AS (
    SELECT c_customer_sk
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_year BETWEEN 1975 AND 1990
      AND c_birth_month = 5
      AND c_birth_day = 15
      AND c_email_address LIKE '%@%.org'
      AND c_current_hdemo_sk IN (6374, 4238)
),
filtered_sales AS (
    SELECT ss_customer_sk
    FROM tpcds.store_sales
    WHERE ss_net_profit > 0
      AND ss_coupon_amt < 500.00
      AND ss_ext_tax BETWEEN 50.00 AND 200.00
      AND ss_quantity >= 1
      AND ss_sales_price > 100.00
      AND ss_sold_date_sk BETWEEN 2450000 AND 2450999
),
intersect_keys AS (
    SELECT c_customer_sk FROM filtered_customers
    INTERSECT
    SELECT ss_customer_sk FROM filtered_sales
)
SELECT
    c.c_customer_id,
    COUNT(*) AS purchase_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    MIN(ss.ss_net_profit) AS min_profit,
    MAX(ss.ss_net_profit) AS max_profit
FROM tpcds.store_sales ss
JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN intersect_keys ik
    ON ik.c_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1975 AND 1990
  AND c.c_birth_month = 5
  AND c.c_birth_day = 15
  AND c.c_email_address LIKE '%@%.org'
  AND c.c_current_hdemo_sk IN (6374, 4238)
  AND ss.ss_net_profit > 0
  AND ss.ss_coupon_amt < 500.00
  AND ss.ss_ext_tax BETWEEN 50.00 AND 200.00
  AND ss.ss_quantity >= 1
  AND ss.ss_sales_price > 100.00
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100
