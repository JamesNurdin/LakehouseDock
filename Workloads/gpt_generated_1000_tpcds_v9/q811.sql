WITH filtered_returns AS (
   SELECT
       sr.sr_customer_sk,
       sr.sr_addr_sk,
       sr.sr_returned_date_sk,
       sr.sr_return_tax,
       sr.sr_refunded_cash,
       sr.sr_return_quantity,
       sr.sr_return_amt
   FROM store_returns AS sr
   WHERE sr.sr_returned_date_sk IN (2452242, 2451133, 2452595)
     AND sr.sr_return_tax > (SELECT AVG(sr2.sr_return_tax) FROM store_returns sr2 WHERE sr2.sr_return_tax > 0)
     AND sr.sr_refunded_cash BETWEEN 100 AND 2000
     AND sr.sr_return_quantity >= 2
),
aggregated_data AS (
   SELECT
       a.ca_state,
       a.ca_zip,
       SUM(fr.sr_return_amt) AS total_return_amt,
       AVG(fr.sr_return_tax) AS avg_return_tax,
       COUNT(*) AS return_cnt
   FROM filtered_returns fr
   JOIN customer c
       ON fr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address a
       ON fr.sr_addr_sk = a.ca_address_sk
   WHERE c.c_customer_id LIKE 'AAAAAAA%'
     AND a.ca_state IN ('AZ', 'TN')
     AND c.c_current_addr_sk = a.ca_address_sk
   GROUP BY a.ca_state, a.ca_zip
)
SELECT
    ca_state,
    ca_zip,
    total_return_amt,
    avg_return_tax,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amt DESC) AS state_rank
FROM aggregated_data
ORDER BY total_return_amt DESC
LIMIT 100
