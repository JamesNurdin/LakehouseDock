WITH union_returns AS (
    SELECT
        d.d_date AS return_date,
        s.s_state AS state,
        'store' AS return_source,
        sr.sr_return_amt_inc_tax AS return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_date AS return_date,
        cc.cc_state AS state,
        'catalog' AS return_source,
        cr.cr_return_amt_inc_tax AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
)
SELECT
    return_date,
    state,
    return_source,
    SUM(return_amount) AS total_return_amount,
    COUNT(*) AS transaction_count,
    AVG(return_amount) AS avg_return_amount
FROM union_returns ur
WHERE EXISTS (
    SELECT 1
    FROM store s_check
    WHERE s_check.s_state = ur.state
      AND s_check.s_number_employees > 30
)
GROUP BY GROUPING SETS (
    (return_date, state, return_source),
    (state, return_source),
    (return_source),
    ()
)
ORDER BY total_return_amount DESC, state, return_source
LIMIT 100
