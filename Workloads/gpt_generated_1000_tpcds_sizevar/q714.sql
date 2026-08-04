WITH catalog_filtered AS (
    SELECT
        cr_reason_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_net_loss
    FROM tpcds.catalog_returns
    WHERE cr_return_amount > 150.00               -- predicate 1
      AND cr_return_quantity >= 2                  -- predicate 2
      AND cr_net_loss BETWEEN 0 AND 400.00         -- predicate 3
      AND cr_return_quantity <> 0                 -- predicate 4
),
store_filtered AS (
    SELECT
        sr_reason_sk,
        sr_fee,
        sr_return_amt,
        sr_store_credit,
        sr_return_quantity
    FROM tpcds.store_returns
    WHERE sr_fee > 35.00                           -- predicate 5
      AND sr_store_credit < 30.00                  -- predicate 6
      AND sr_return_amt BETWEEN 20.00 AND 2000.00
)
SELECT
    r.r_reason_desc,
    COUNT(*) AS total_transactions,
    SUM(cf.cr_return_amount) AS total_catalog_return_amount,
    AVG(sf.sr_return_amt) AS avg_store_return_amount,
    SUM(
        CASE
            WHEN cf.cr_net_loss > 200.00 THEN cf.cr_net_loss * 0.90
            ELSE cf.cr_net_loss * 0.95
        END
    ) AS adjusted_net_loss,
    (SELECT COUNT(*) FROM tpcds.catalog_returns cr2 WHERE cr2.cr_return_quantity > 0) AS catalog_row_count
FROM catalog_filtered cf
JOIN tpcds.reason r
  ON cf.cr_reason_sk = r.r_reason_sk
JOIN store_filtered sf
  ON sf.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAADAAAAAAA')                         -- predicate 7
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr_sub
        WHERE sr_sub.sr_reason_sk = r.r_reason_sk
          AND sr_sub.sr_fee > 40.00                                          -- predicate 8
    )
  AND r.r_reason_sk IN (
        SELECT cr_reason_sk FROM tpcds.catalog_returns WHERE cr_return_quantity > 5
        INTERSECT
        SELECT sr_reason_sk FROM tpcds.store_returns   WHERE sr_fee > 50.00
    )
GROUP BY r.r_reason_desc
HAVING SUM(cf.cr_return_amount) > 500.00
ORDER BY total_catalog_return_amount DESC
LIMIT 100
