WITH ca_customers AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           ca.ca_state
    FROM customer c
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
)
SELECT r.c_customer_id,
       r.state,
       r.total_amount,
       r.transaction_type
FROM (
    SELECT c.c_customer_id,
           ca.ca_state AS state,
           SUM(cr.cr_return_amount) AS total_amount,
           'RETURN' AS transaction_type
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ca_customers cc
      ON c.c_customer_sk = cc.c_customer_sk
    WHERE cr.cr_return_amount > 1000
      AND ca.ca_state = 'CA'
    GROUP BY c.c_customer_id, ca.ca_state
) r
UNION ALL
SELECT s.c_customer_id,
       s.state,
       s.total_amount,
       s.transaction_type
FROM (
    SELECT c.c_customer_id,
           ca.ca_state AS state,
           SUM(ws.ws_ext_sales_price) AS total_amount,
           'SALE' AS transaction_type
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ca_customers cc
      ON c.c_customer_sk = cc.c_customer_sk
    WHERE ws.ws_ext_sales_price > 2000
      AND ca.ca_state = 'CA'
    GROUP BY c.c_customer_id, ca.ca_state
) s
ORDER BY total_amount DESC
