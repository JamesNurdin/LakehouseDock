WITH reason_price AS (
        SELECT sr.sr_store_sk
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc LIKE '%price%'
    ),
    reason_work AS (
        SELECT sr.sr_store_sk
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc LIKE '%work%'
    ),
    intersect_stores AS (
        SELECT sr_store_sk FROM reason_price
        INTERSECT
        SELECT sr_store_sk FROM reason_work
    ),
    high_amount_stores AS (
        SELECT sr.sr_store_sk
        FROM store_returns sr
        WHERE sr.sr_return_amt > 1000
    ),
    target_stores AS (
        SELECT sr_store_sk FROM intersect_stores
        EXCEPT
        SELECT sr_store_sk FROM high_amount_stores
    )
SELECT ts.sr_store_sk,
       COUNT(*) AS total_returns,
       SUM(CASE WHEN sr.sr_return_amt > 500 THEN 1 ELSE 0 END) AS returns_over_500,
       (SELECT MAX(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = ts.sr_store_sk) AS max_return_amount
FROM store_returns sr
JOIN target_stores ts ON sr.sr_store_sk = ts.sr_store_sk
GROUP BY ts.sr_store_sk
ORDER BY total_returns DESC, ts.sr_store_sk
LIMIT 50
