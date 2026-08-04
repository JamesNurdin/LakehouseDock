WITH agg_store_returns AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns,
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_fee > 40.00               -- filter 1: high fees
      AND sr_refunded_cash < 500.00    -- filter 2: modest cash refunds
    GROUP BY sr_store_sk, sr_reason_sk
),
cat_ret AS (
    SELECT
        cr_reason_sk,
        SUM(cr_return_amount) AS total_cr_amount,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_cr_return_amt
    FROM catalog_returns
    WHERE cr_reversed_charge > 100.00   -- filter 3: sizable reversed charges
    GROUP BY cr_reason_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    r.r_reason_desc,
    agg.total_return_amt,
    agg.cnt_returns,
    agg.avg_return_amt,
    cr.total_cr_amount,
    cr.return_cnt,
    (agg.avg_return_amt - cr.avg_cr_return_amt) AS avg_return_diff
FROM agg_store_returns AS agg
RIGHT OUTER JOIN store AS s
    ON agg.sr_store_sk = s.s_store_sk
FULL OUTER JOIN reason AS r
    ON agg.sr_reason_sk = r.r_reason_sk
LEFT JOIN cat_ret AS cr
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE s.s_zip = '55752'                                   -- filter 4: specific store zip
  AND r.r_reason_desc LIKE '%damaged%'                     -- filter 5: specific reason description
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = 7028053
          AND cr2.cr_reason_sk = r.r_reason_sk
    )                                                       -- sub‑query filter
ORDER BY agg.total_return_amt DESC
LIMIT 100
