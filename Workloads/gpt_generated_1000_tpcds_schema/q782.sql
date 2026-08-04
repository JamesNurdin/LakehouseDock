WITH sr_full AS (
   SELECT
       sr.sr_returned_date_sk AS date_sk,
       sr.sr_return_quantity,
       sr.sr_net_loss,
       c.c_customer_id
   FROM store_returns sr
   FULL OUTER JOIN customer c
       ON sr.sr_customer_sk = c.c_customer_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2451920
),
sr_expanded AS (
   SELECT
       date_sk,
       c_customer_id,
       part AS cust_id_part,
       sr_return_quantity,
       sr_net_loss
   FROM sr_full
   CROSS JOIN UNNEST(split(c_customer_id, '_')) AS t (part)
),
web_full AS (
   SELECT
       wr.wr_returned_date_sk AS date_sk,
       wr.wr_return_quantity,
       wr.wr_net_loss,
       c.c_customer_id
   FROM web_returns wr
   JOIN customer c
       ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE wr.wr_returned_date_sk BETWEEN 2451910 AND 2451920
),
web_expanded AS (
   SELECT
       date_sk,
       c_customer_id,
       part AS cust_id_part,
       wr_return_quantity,
       wr_net_loss
   FROM web_full
   CROSS JOIN UNNEST(split(c_customer_id, '_')) AS t (part)
),
sr_keys AS (
   SELECT DISTINCT c_customer_id FROM sr_full
),
web_keys AS (
   SELECT DISTINCT c_customer_id FROM web_full
),
store_only_customers AS (
   SELECT c_customer_id FROM sr_keys
   EXCEPT
   SELECT c_customer_id FROM web_keys
)
SELECT
   e.date_sk,
   e.c_customer_id,
   e.cust_id_part,
   e.sr_return_quantity AS quantity,
   e.sr_net_loss AS net_loss,
   'store' AS source
FROM sr_expanded e
WHERE e.c_customer_id IN (SELECT c_customer_id FROM store_only_customers)

UNION ALL

SELECT
   e.date_sk,
   e.c_customer_id,
   e.cust_id_part,
   e.wr_return_quantity AS quantity,
   e.wr_net_loss AS net_loss,
   'web' AS source
FROM web_expanded e
WHERE e.c_customer_id NOT IN (SELECT c_customer_id FROM sr_keys)

ORDER BY date_sk DESC, quantity DESC
LIMIT 100
