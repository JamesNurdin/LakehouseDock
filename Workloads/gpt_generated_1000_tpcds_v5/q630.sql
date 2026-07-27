WITH recent_dates AS (
   SELECT d_date_sk
   FROM date_dim
   WHERE d_current_month = 'Y'
),
shipto AS (
   SELECT
       'ShipTo' AS src,
       ca.ca_county,
       COUNT(DISTINCT c.c_customer_sk) AS customer_cnt,
       (SELECT COUNT(*) FROM customer) AS total_customers
   FROM recent_dates rd
   JOIN inventory i ON i.inv_date_sk = rd.d_date_sk
   JOIN customer c ON c.c_first_shipto_date_sk = rd.d_date_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE i.inv_quantity_on_hand > 0
     AND ca.ca_state = 'CA'
   GROUP BY ca.ca_county
),
firstsale AS (
   SELECT
       'FirstSale' AS src,
       ca.ca_county,
       COUNT(DISTINCT c.c_customer_sk) AS customer_cnt,
       (SELECT COUNT(*) FROM customer) AS total_customers
   FROM recent_dates rd
   JOIN inventory i ON i.inv_date_sk = rd.d_date_sk
   JOIN customer c ON c.c_first_sales_date_sk = rd.d_date_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE i.inv_quantity_on_hand > 0
     AND ca.ca_state = 'CA'
     AND c.c_birth_month = 5
   GROUP BY ca.ca_county
)
SELECT src, ca_county, customer_cnt, total_customers
FROM shipto
UNION ALL
SELECT src, ca_county, customer_cnt, total_customers
FROM firstsale
ORDER BY ca_county, src
