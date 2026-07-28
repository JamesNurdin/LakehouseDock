WITH filtered_returns AS (
    SELECT
        sr.sr_addr_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_refunded_cash,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_quantity >= 10
      AND sr.sr_return_quantity <= 100
      AND sr.sr_fee BETWEEN 10 AND 40
      AND sr.sr_refunded_cash > 30
      AND sr.sr_return_amt > 50
      AND sr.sr_net_loss >= 0
)
SELECT
    ca.ca_state,
    ca.ca_county,
    ca.ca_street_name,
    COUNT(DISTINCT fr.sr_customer_sk) AS distinct_customers,
    SUM(fr.sr_return_quantity) AS total_quantity,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_fee) AS avg_fee,
    MIN(fr.sr_refunded_cash) AS min_refunded_cash,
    MAX(fr.sr_refunded_cash) AS max_refunded_cash
FROM filtered_returns fr
JOIN customer_address ca
  ON fr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_county IN ('Madison County', 'Barry County')
  AND ca.ca_street_number = '31'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = fr.sr_customer_sk
          AND sr2.sr_return_quantity > 50
    )
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = fr.sr_customer_sk
          AND sr3.sr_refunded_cash > 200
    )
GROUP BY ca.ca_state, ca.ca_county, ca.ca_street_name
HAVING SUM(fr.sr_return_amt) > (
        SELECT AVG(sr4.sr_return_amt)
        FROM store_returns sr4
    )
ORDER BY total_quantity DESC, distinct_customers DESC
LIMIT 100
