/* goal: Compare web sales net revenue with store return amounts per state and date, focusing on business hours, and rank states by total metric while keeping only above‑average rows */
WITH web AS (
   SELECT
       ca.ca_state AS state,
       ws.ws_sold_date_sk AS date_sk,
       ws.ws_net_paid_inc_ship_tax AS metric_amount,
       'web' AS source_type
   FROM tpcds.web_sales ws
   JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND ca.ca_state IN ('CA', 'TX', 'NY')
),
ret AS (
   SELECT
       ca.ca_state AS state,
       sr.sr_returned_date_sk AS date_sk,
       sr.sr_return_amt_inc_tax AS metric_amount,
       'return' AS source_type
   FROM tpcds.store_returns sr
   JOIN tpcds.time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND ca.ca_state IN ('CA', 'TX', 'NY')
     AND EXISTS (
         SELECT 1
         FROM tpcds.web_sales ws2
         WHERE ws2.ws_bill_addr_sk = sr.sr_addr_sk
           AND ws2.ws_sold_date_sk = sr.sr_returned_date_sk
     )
),
combined AS (
   SELECT * FROM web
   UNION ALL
   SELECT * FROM ret
)
SELECT
   state,
   date_sk,
   metric_amount,
   source_type,
   SUM(metric_amount) OVER (PARTITION BY state) AS state_total_metric,
   ROW_NUMBER() OVER (PARTITION BY state ORDER BY metric_amount DESC) AS rank_within_state
FROM combined
WHERE metric_amount > (SELECT AVG(metric_amount) FROM combined)
ORDER BY state, rank_within_state
LIMIT 100
