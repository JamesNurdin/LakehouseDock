WITH agg_returns AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr_return_tax) AS min_return_tax,
        MAX(sr_return_tax) AS max_return_tax
    FROM store_returns
    WHERE sr_return_tax > 20
      AND sr_return_time_sk BETWEEN 41000 AND 47000
      AND sr_reversed_charge < 300
    GROUP BY sr_reason_sk
)
SELECT
    r.r_reason_desc,
    a.total_return_inc_tax,
    a.avg_return_tax,
    a.return_cnt,
    CASE
        WHEN a.total_return_inc_tax > 10000 THEN 'High'
        WHEN a.total_return_inc_tax > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS amt_category,
    a.min_return_tax,
    a.max_return_tax
FROM agg_returns a
JOIN reason r
    ON a.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%size%'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = r.r_reason_sk
          AND sr2.sr_reversed_charge > 250
    )
ORDER BY a.total_return_inc_tax DESC
LIMIT 100
