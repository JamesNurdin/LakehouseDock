WITH recent_returns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_current_quarter = 'Y'
      AND d.d_dom IN (5, 12, 17)
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    rr.total_return AS return_amount,
    rr.return_cnt AS transaction_count,
    'Recent' AS period
FROM recent_returns rr
JOIN customer c ON rr.sr_customer_sk = c.c_customer_sk
WHERE rr.total_return > 100

UNION ALL

SELECT
    c2.c_customer_id,
    old_agg.total_return AS return_amount,
    old_agg.return_cnt AS transaction_count,
    'Older' AS period
FROM (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_dom = 4
    GROUP BY sr.sr_customer_sk
) old_agg
JOIN customer c2 ON old_agg.sr_customer_sk = c2.c_customer_sk
WHERE old_agg.total_return <= 100
  AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = c2.c_current_addr_sk
          AND ca.ca_state = 'CA'
    )
ORDER BY return_amount DESC
LIMIT 100
