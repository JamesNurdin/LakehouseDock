WITH max_fee_per_store AS (
    SELECT sr_store_sk, max(sr_fee) AS max_fee
    FROM store_returns
    GROUP BY sr_store_sk
)
SELECT d.d_quarter_name,
       SUM(sr.sr_return_amt) AS total_return_amount,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_cnt,
       mf.max_fee AS store_max_fee
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN max_fee_per_store mf ON sr.sr_store_sk = mf.sr_store_sk
WHERE sr.sr_reversed_charge > 50
  AND d.d_current_month = 'Y'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sr.sr_store_sk
          AND sr2.sr_fee > 20
      )
GROUP BY d.d_quarter_name, mf.max_fee

UNION ALL

SELECT d.d_quarter_name,
       SUM(sr.sr_return_amt) AS total_return_amount,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_cnt,
       mf.max_fee AS store_max_fee
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN max_fee_per_store mf ON sr.sr_store_sk = mf.sr_store_sk
WHERE sr.sr_store_credit > 30
  AND d.d_current_month = 'N'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sr.sr_store_sk
          AND sr2.sr_fee > 20
      )
GROUP BY d.d_quarter_name, mf.max_fee
ORDER BY total_return_amount DESC
LIMIT 100
