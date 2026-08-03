WITH returned_by_refunded_addr AS (
       SELECT
           ca.ca_state AS state,
           ca.ca_city AS city,
           SUM(wr.wr_return_amt) AS total_refund,
           COUNT(*) AS cnt_returns
       FROM tpcds.web_returns wr
       JOIN tpcds.customer_address ca
         ON wr.wr_refunded_addr_sk = ca.ca_address_sk
       WHERE ca.ca_zip BETWEEN '40000' AND '60000'
         AND wr.wr_return_quantity > 20
       GROUP BY ca.ca_state, ca.ca_city
   ),
   returned_by_returning_addr AS (
       SELECT
           ca.ca_state AS state,
           ca.ca_city AS city,
           SUM(wr.wr_return_amt) AS total_refund,
           COUNT(*) AS cnt_returns
       FROM tpcds.web_returns wr
       JOIN tpcds.customer_address ca
         ON wr.wr_returning_addr_sk = ca.ca_address_sk
       WHERE ca.ca_zip BETWEEN '60001' AND '80000'
         AND EXISTS (
             SELECT 1 FROM tpcds.web_returns wr2
             WHERE wr2.wr_refunded_addr_sk = ca.ca_address_sk
               AND wr2.wr_return_amt > 100
             LIMIT 1
         )
       GROUP BY ca.ca_state, ca.ca_city
   )
SELECT
    state,
    city,
    total_refund,
    cnt_returns,
    'refunded' AS address_role
FROM returned_by_refunded_addr
UNION ALL
SELECT
    state,
    city,
    total_refund,
    cnt_returns,
    'returning' AS address_role
FROM returned_by_returning_addr
ORDER BY total_refund DESC
LIMIT 100
