WITH refunded AS (
   SELECT ca.ca_state,
          SUM(wr.wr_net_loss) AS total_loss,
          COUNT(DISTINCT ca.ca_address_id) AS distinct_addresses
   FROM web_returns wr
   JOIN customer_address ca
     ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE wr.wr_fee > (SELECT AVG(wr2.wr_fee) FROM web_returns wr2)
     AND ca.ca_city = 'Seattle'
   GROUP BY ca.ca_state
   HAVING SUM(wr.wr_net_loss) > 500
),
returning AS (
   SELECT ca.ca_state,
          SUM(wr.wr_net_loss) AS total_loss,
          COUNT(DISTINCT ca.ca_address_id) AS distinct_addresses
   FROM web_returns wr
   JOIN customer_address ca
     ON wr.wr_returning_addr_sk = ca.ca_address_sk
   WHERE EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
          AND wr2.wr_fee > 50
   )
     AND ca.ca_suite_number LIKE 'Suite %'
   GROUP BY ca.ca_state
   HAVING COUNT(DISTINCT ca.ca_address_id) > 5
)
SELECT state,
       total_loss,
       distinct_addresses,
       source
FROM (
   SELECT ca_state AS state,
          total_loss,
          distinct_addresses,
          'refunded' AS source
   FROM refunded
   UNION ALL
   SELECT ca_state AS state,
          total_loss,
          distinct_addresses,
          'returning' AS source
   FROM returning
) q
ORDER BY total_loss DESC
