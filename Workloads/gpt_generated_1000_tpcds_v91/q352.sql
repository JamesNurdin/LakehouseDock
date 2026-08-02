WITH store_customers AS (
   SELECT c.c_customer_sk,
          SUM(ss.ss_net_paid) AS total_spent,
          COUNT(DISTINCT ss.ss_ticket_number) AS txns,
          CASE WHEN regexp_like(c.c_email_address, '^.*@gmail\\.com$') THEN 1 ELSE 0 END AS gmail_user
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE t.t_shift = 'first'
     AND c.c_preferred_cust_flag LIKE 'Y%'
   GROUP BY c.c_customer_sk, c.c_email_address
),
web_customers AS (
   SELECT c.c_customer_sk,
          SUM(ws.ws_net_paid) AS total_spent,
          COUNT(DISTINCT ws.ws_order_number) AS txns,
          CASE WHEN regexp_like(c.c_email_address, '^.*@gmail\\.com$') THEN 1 ELSE 0 END AS gmail_user
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE t.t_shift = 'first'
     AND c.c_preferred_cust_flag LIKE 'Y%'
   GROUP BY c.c_customer_sk, c.c_email_address
),
combined_customers AS (
   SELECT c_customer_sk, total_spent, txns, gmail_user FROM store_customers
   UNION
   SELECT c_customer_sk, total_spent, txns, gmail_user FROM web_customers
),
return_customers AS (
   SELECT DISTINCT c.c_customer_sk
   FROM web_returns wr
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE wr.wr_return_amt > 500
),
active_customers AS (
   SELECT c_customer_sk, total_spent, txns, gmail_user
   FROM combined_customers
   EXCEPT
   SELECT rc.c_customer_sk, CAST(0 AS DECIMAL(7,2)), 0, 0
   FROM return_customers rc
)
SELECT ac.c_customer_sk,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       c.c_email_address,
       ac.total_spent,
       ac.txns,
       ac.gmail_user,
       (SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ac.c_customer_sk) AS web_total_paid
FROM active_customers ac
JOIN customer c ON ac.c_customer_sk = c.c_customer_sk
ORDER BY ac.total_spent DESC
LIMIT 100
