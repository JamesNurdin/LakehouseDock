/*
  Goal: Identify high‑value customers using string‑based filters on email domains and address fields, 
  compare their spend against the overall average, and also surface frequent shoppers on "Main" streets
  who have used large coupons. The query demonstrates REGEXP_EXTRACT, REGEXP_LIKE, LIKE, SUBSTRING,
  scalar subqueries, EXISTS, and a UNION ALL set operation, ending with ordering by total spend.
*/
WITH sales_agg AS (
    SELECT
        ss.ss_customer_sk            AS cust_sk,
        SUM(ss.ss_net_paid)          AS total_spent,
        COUNT(*)                     AS txn_cnt,
        MIN(ss.ss_sold_date_sk)      AS first_purchase_date,
        MAX(ss.ss_sold_date_sk)      AS last_purchase_date
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
)
SELECT
    combined.c_customer_id,
    combined.full_name,
    combined.ca_city,
    combined.total_spent,
    combined.email_domain
FROM (
    -- 1️⃣  High‑spend customers with a Gmail address and a street type that starts with "St"
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name)               AS full_name,
        ca.ca_city,
        agg.total_spent,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1)          AS email_domain
    FROM sales_agg agg
    JOIN customer c               ON agg.cust_sk = c.c_customer_sk
    JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE agg.total_spent > (SELECT AVG(total_spent) FROM sales_agg)               -- scalar subquery
      AND REGEXP_LIKE(
            REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1),
            '^gmail\\.com$'
          )
      AND ca.ca_street_type LIKE 'St%'

    UNION ALL

    -- 2️⃣  Frequent shoppers on streets containing "Main" who have used a large coupon
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name)               AS full_name,
        ca.ca_city,
        agg.total_spent,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1)          AS email_domain
    FROM sales_agg agg
    JOIN customer c               ON agg.cust_sk = c.c_customer_sk
    JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE agg.txn_cnt > 50
      AND ca.ca_street_name LIKE '%Main%'
      AND SUBSTRING(c.c_preferred_cust_flag, 1, 1) = 'Y'                     -- string processing
      AND EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
              AND ss2.ss_coupon_amt > 1000
            LIMIT 1
          )
) AS combined
ORDER BY combined.total_spent DESC
