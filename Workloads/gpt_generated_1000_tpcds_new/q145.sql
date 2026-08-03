/* Goal: Calculate aggregated return amounts per return reason, applying multiple realistic filters, comparing against a scalar subquery, and keeping only rows where the customer has at least one other high‑quantity return. */
WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
) 
SELECT
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_inc_tax,
    MIN(sr.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(sr.sr_return_amt_inc_tax) AS max_return_inc_tax,
    SUM(sr.sr_fee) AS total_fee
FROM sampled_returns sr
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_amt_inc_tax > 500.00                     -- filter 1
  AND sr.sr_return_amt_inc_tax < 3000.00                    -- filter 2
  AND sr.sr_return_ship_cost BETWEEN 20.00 AND 2000.00    -- filter 3
  AND sr.sr_fee > 15.00                                    -- filter 4
  AND sr.sr_return_quantity BETWEEN 1 AND 5               -- filter 5
  AND r.r_reason_id = 'AAAAAAAANAAAAAAA'                    -- filter 6
  AND sr.sr_return_amt_inc_tax > (
        SELECT MAX(sr2.sr_return_amt_inc_tax)
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity = 1
    )                                                       -- scalar subquery comparison
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = sr.sr_customer_sk
          AND sr3.sr_return_quantity > 5
    )                                                       -- correlated EXISTS filter
GROUP BY r.r_reason_desc
ORDER BY total_return_inc_tax DESC
LIMIT 100
