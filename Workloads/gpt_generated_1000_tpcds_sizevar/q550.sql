WITH filtered_customers AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_email_address,
       c.c_first_name,
       c.c_last_name,
       ca.ca_city,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM customer c
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE REGEXP_LIKE(c.c_email_address, '^.+@[^\\.]+\\.com$')
     AND ca.ca_city LIKE 'A%'
),
sales_agg AS (
   SELECT
       ss.ss_customer_sk,
       SUM(ss.ss_net_paid) AS total_net_paid,
       COUNT(*) AS cnt_sales
   FROM store_sales ss
   GROUP BY ss.ss_customer_sk
)
SELECT
    fc.c_customer_id,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    fc.ca_city,
    sa.total_net_paid,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = fc.c_customer_sk) AS return_cnt,
    REGEXP_EXTRACT(fc.c_email_address, '@(.+)$') AS email_domain
FROM filtered_customers fc
JOIN sales_agg sa ON fc.c_customer_sk = sa.ss_customer_sk
WHERE fc.c_customer_id IN (
    SELECT c_customer_id FROM filtered_customers WHERE ib_lower_bound < 30000
    EXCEPT
    SELECT c_customer_id FROM filtered_customers WHERE ib_upper_bound > 80000
)
  AND sa.total_net_paid > 10000
UNION DISTINCT
SELECT
    fc.c_customer_id,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    fc.ca_city,
    NULL AS total_net_paid,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = fc.c_customer_sk) AS return_cnt,
    REGEXP_EXTRACT(fc.c_email_address, '@(.+)$') AS email_domain
FROM filtered_customers fc
WHERE fc.c_customer_id IN (
    SELECT c_customer_id FROM filtered_customers WHERE ib_lower_bound < 30000
    EXCEPT
    SELECT c_customer_id FROM filtered_customers WHERE ib_upper_bound > 80000
)
  AND (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = fc.c_customer_sk) > 5
ORDER BY total_net_paid DESC NULLS LAST, c_customer_id
