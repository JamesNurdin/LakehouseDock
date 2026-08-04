WITH sampled_store_sales AS (
   SELECT ss_sold_date_sk, ss_customer_sk, ss_item_sk, ss_ticket_number, ss_ext_sales_price, ss_net_paid
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
customer_name_filtered AS (
   SELECT c_customer_sk,
          c_first_name,
          c_last_name,
          c_email_address,
          c_current_addr_sk
   FROM customer
   WHERE regexp_like(c_first_name, '^[A-M]')
     AND lower(c_email_address) LIKE '%@example.com'
),
address_filtered AS (
   SELECT ca_address_sk,
          ca_street_number,
          ca_street_type,
          ca_suite_number
   FROM customer_address
   WHERE regexp_like(ca_suite_number, '^Suite [1-9][0-9]{0,2}$')
     AND ca_street_type LIKE '%Drive%'
),
web_sales_filtered AS (
   SELECT ws_bill_customer_sk,
          ws_order_number,
          ws_net_paid_inc_ship,
          ws_web_site_sk
   FROM web_sales
   WHERE ws_net_paid_inc_ship > 1000
     AND ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer_name_filtered)
),
web_customer_keys AS (
   SELECT DISTINCT ws_bill_customer_sk AS cust_sk
   FROM web_sales
),
store_customer_keys AS (
   SELECT DISTINCT ss_customer_sk AS cust_sk
   FROM store_sales
),
web_not_store AS (
   SELECT cust_sk FROM web_customer_keys
   EXCEPT
   SELECT cust_sk FROM store_customer_keys
),
both_customer_keys AS (
   SELECT cust_sk FROM web_customer_keys
   INTERSECT
   SELECT cust_sk FROM store_customer_keys
),
full_customer_address AS (
   SELECT cnf.c_customer_sk,
          cnf.c_first_name,
          cnf.c_last_name,
          cnf.c_email_address,
          af.ca_street_number,
          af.ca_street_type,
          af.ca_suite_number
   FROM customer_name_filtered cnf
   FULL OUTER JOIN address_filtered af
     ON cnf.c_current_addr_sk = af.ca_address_sk
),
final_aggregation AS (
   SELECT
     c.c_customer_sk,
     concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
     regexp_extract(c.c_email_address, '@([^\\.]+\\..+)', 1) AS email_domain,
     COUNT(DISTINCT ws.ws_order_number) AS web_orders,
     SUM(ws.ws_net_paid_inc_ship) AS total_web_spent,
     COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_count,
     SUM(sr.sr_return_amt) AS total_store_returns
   FROM customer c
   LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
   WHERE c.c_customer_sk IN (SELECT cust_sk FROM both_customer_keys)
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
)
SELECT
  fa.c_customer_sk,
  fa.full_name,
  fa.email_domain,
  fa.web_orders,
  fa.total_web_spent,
  fa.store_returns_count,
  fa.total_store_returns,
  fca.ca_street_number,
  fca.ca_street_type,
  fca.ca_suite_number
FROM final_aggregation fa
LEFT JOIN full_customer_address fca ON fa.c_customer_sk = fca.c_customer_sk
WHERE fa.full_name LIKE '%Smith%'
ORDER BY fa.total_web_spent DESC
LIMIT 100
