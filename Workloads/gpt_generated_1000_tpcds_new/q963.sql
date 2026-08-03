WITH sampled_ws AS (
   SELECT ws_order_number,
          ws_bill_customer_sk,
          ws_item_sk,
          ws_sales_price,
          ws_quantity,
          ws_sold_date_sk
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
),

customer_purchases AS (
   SELECT DISTINCT c.c_customer_sk AS cust_sk
   FROM sampled_ws sw
   JOIN item i ON sw.ws_item_sk = i.i_item_sk
   JOIN customer c ON sw.ws_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(i.i_item_desc, '\\d{2}')
     AND c.c_first_name LIKE 'J%'
),

high_spenders AS (
   SELECT ws_bill_customer_sk AS cust_sk
   FROM sampled_ws
   GROUP BY ws_bill_customer_sk
   HAVING SUM(ws_sales_price * ws_quantity) > 500
),

returning_customers AS (
   SELECT DISTINCT wr_returning_customer_sk AS cust_sk
   FROM web_returns
),

eligible_customers AS (
   SELECT cust_sk
   FROM customer_purchases
   INTERSECT
   SELECT cust_sk
   FROM high_spenders
   EXCEPT
   SELECT cust_sk
   FROM returning_customers
)

SELECT CONCAT('State ', ca.ca_state) AS state_label,
       SUBSTRING(ca.ca_zip, 1, 3) AS zip_prefix,
       COUNT(*) AS customer_count
FROM eligible_customers ec
JOIN customer c ON ec.cust_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca.ca_state, ca.ca_zip
ORDER BY customer_count DESC
