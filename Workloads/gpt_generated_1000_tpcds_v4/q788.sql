WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_current_addr_sk,
        c_birth_year,
        c_last_review_date,
        c_preferred_cust_flag
    FROM tpcds.customer
    WHERE c_first_shipto_date_sk IN (2451039, 2451827, 2452288)
      AND c_last_review_date >= 2452500
      AND c_preferred_cust_flag = 'Y'
)
SELECT
    ca.ca_state,
    COUNT(DISTINCT fc.c_customer_sk) AS customer_cnt,
    AVG(fc.c_birth_year) AS avg_birth_year,
    MAX(fc.c_last_review_date) AS max_review_date,
    SUM(CASE WHEN fc.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_cnt
FROM filtered_customers fc
JOIN tpcds.customer_address ca
    ON fc.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_street_name LIKE '%Woodland%'
  AND ca.ca_suite_number = 'Suite 80 '
  AND ca.ca_gmt_offset = -7.00
  AND EXISTS (
        SELECT 1
        FROM tpcds.customer_address ca2
        WHERE ca2.ca_state = ca.ca_state
          AND ca2.ca_zip LIKE '9%'
      )
GROUP BY ca.ca_state
HAVING COUNT(DISTINCT fc.c_customer_sk) >= 5
ORDER BY customer_cnt DESC
LIMIT 100
