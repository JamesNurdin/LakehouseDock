SELECT state,
       total_return_amount,
       total_net_loss,
       avg_return_quantity
FROM (
   SELECT ca.ca_state AS state,
          SUM(sr.sr_return_amt) AS total_return_amount,
          SUM(sr.sr_net_loss) AS total_net_loss,
          AVG(sr.sr_return_quantity) AS avg_return_quantity
   FROM store_returns sr
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE sr.sr_return_quantity > 30
     AND sr.sr_store_credit > 20
     AND ca.ca_suite_number = 'Suite A'
   GROUP BY ca.ca_state
   UNION
   SELECT ca.ca_state AS state,
          SUM(sr.sr_return_amt) AS total_return_amount,
          SUM(sr.sr_net_loss) AS total_net_loss,
          AVG(sr.sr_return_quantity) AS avg_return_quantity
   FROM store_returns sr
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE sr.sr_return_quantity BETWEEN 10 AND 20
     AND sr.sr_store_credit < 30
     AND ca.ca_street_type = 'Avenue'
     AND EXISTS (
         SELECT 1
         FROM store_returns sr2
         WHERE sr2.sr_addr_sk = sr.sr_addr_sk
           AND sr2.sr_return_quantity = 13
     )
   GROUP BY ca.ca_state
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
