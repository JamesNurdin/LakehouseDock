WITH
  customer_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_state,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
      COUNT(sr.sr_ticket_number) AS return_cnt,
      CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt_inc_tax IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
  ),
  reason_agg AS (
    SELECT
      r.r_reason_sk,
      r.r_reason_desc,
      COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
      SUM(DISTINCT sr.sr_return_amt) AS distinct_return_amt
    FROM reason r
    FULL OUTER JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_sk, r.r_reason_desc
  )
SELECT
  cr.c_customer_sk AS key_id,
  cr.c_first_name || ' ' || cr.c_last_name AS name,
  cr.total_return_inc_tax AS metric1,
  cr.return_cnt AS metric2,
  cr.return_level AS category,
  (SELECT AVG(sr3.sr_return_amt) FROM store_returns sr3) AS avg_return_all
FROM customer_returns cr
WHERE cr.c_customer_sk NOT IN (
  SELECT sr.sr_customer_sk FROM store_returns sr WHERE sr.sr_return_amt_inc_tax > 5000
)
UNION ALL
SELECT
  ra.r_reason_sk AS key_id,
  ra.r_reason_desc AS name,
  ra.distinct_return_amt AS metric1,
  ra.distinct_tickets AS metric2,
  CASE WHEN ra.distinct_return_amt > 2000 THEN 'HIGH' ELSE 'LOW' END AS category,
  (SELECT AVG(sr3.sr_return_amt) FROM store_returns sr3) AS avg_return_all
FROM reason_agg ra
WHERE ra.r_reason_sk NOT IN (
  SELECT r2.r_reason_sk FROM reason r2 WHERE r2.r_reason_desc LIKE '%damaged%'
)
ORDER BY metric1 DESC
LIMIT 100
