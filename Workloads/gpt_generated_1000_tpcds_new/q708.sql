WITH combined AS (
    SELECT
        sr.sr_store_sk,
        d.d_date,
        d.d_year,
        sr.sr_return_amt_inc_tax,
        CASE WHEN sr.sr_return_amt_inc_tax > 200 THEN 'High' ELSE 'Medium' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn_year,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_hdemo_sk = sr.sr_hdemo_sk) AS demo_return_cnt
    FROM store_returns sr
    FULL OUTER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_week_seq >= 5
        AND d.d_week_seq <= 15
        AND d.d_moy IN (3, 5, 7)
        AND d.d_current_day = 'N'
        AND sr.sr_fee >= 10

    UNION DISTINCT

    SELECT
        sr.sr_store_sk,
        d.d_date,
        d.d_year,
        sr.sr_return_amt_inc_tax,
        CASE WHEN sr.sr_return_amt_inc_tax > 150 THEN 'High' ELSE 'Low' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sr.sr_return_amt_inc_tax ASC) AS rn_year,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_hdemo_sk = sr.sr_hdemo_sk) AS demo_return_cnt
    FROM store_returns sr
    FULL OUTER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_week_seq BETWEEN 10 AND 20
        AND d.d_moy NOT IN (8, 11)
        AND d.d_current_day = 'N'
        AND sr.sr_fee BETWEEN 5 AND 25
        AND sr.sr_return_amt_inc_tax < 100
)
SELECT
    sr_store_sk,
    d_date,
    d_year,
    sr_return_amt_inc_tax,
    return_category,
    rn_year,
    demo_return_cnt
FROM combined
WHERE rn_year <= 10
ORDER BY d_year DESC, sr_return_amt_inc_tax DESC
LIMIT 100
