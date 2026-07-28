WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        d.d_quarter_name,
        d.d_fy_week_seq,
        d.d_day_name,
        (d.d_quarter_name || '_' || CAST(d.d_fy_week_seq AS varchar)) AS period_key
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_quarter_name, '^190[0-9]Q[12]$')
      AND d.d_day_name LIKE '%day'
),
overall_avg AS (
    SELECT AVG(sr_return_amt) AS overall_avg_return_amt
    FROM store_returns
)
SELECT
    fr.sr_store_sk,
    fr.period_key,
    COUNT(DISTINCT fr.sr_returned_date_sk) AS distinct_return_days,
    AVG(fr.sr_return_amt) AS avg_return_amt,
    SUM(fr.sr_return_tax) AS total_return_tax,
    CASE
        WHEN AVG(fr.sr_return_amt) > oa.overall_avg_return_amt THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM filtered_returns fr
CROSS JOIN overall_avg oa
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = fr.sr_store_sk
      AND sr2.sr_return_tax > 50.00
)
GROUP BY fr.sr_store_sk, fr.period_key, oa.overall_avg_return_amt
ORDER BY avg_return_amt DESC
LIMIT 100
