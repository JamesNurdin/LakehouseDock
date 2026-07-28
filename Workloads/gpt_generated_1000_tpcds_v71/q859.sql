WITH recent_reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_id LIKE 'AAAAAAA%'
)
SELECT
    reason,
    return_amount,
    amount_category,
    rn,
    avg_return_for_reason
FROM (
    SELECT 
        r.r_reason_desc AS reason,
        cr.cr_return_amount AS return_amount,
        CASE 
            WHEN cr.cr_return_amount > 100 THEN 'High'
            WHEN cr.cr_return_amount > 50 THEN 'Medium'
            ELSE 'Low'
        END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY cr.cr_return_amount DESC) AS rn,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_reason_sk = cr.cr_reason_sk
        ) AS avg_return_for_reason
    FROM catalog_returns cr
    JOIN recent_reasons r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17

    UNION ALL

    SELECT 
        r.r_reason_desc AS reason,
        sr.sr_return_amt AS return_amount,
        CASE 
            WHEN sr.sr_return_amt > 100 THEN 'High'
            WHEN sr.sr_return_amt > 50 THEN 'Medium'
            ELSE 'Low'
        END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY sr.sr_return_amt DESC) AS rn,
        (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = sr.sr_reason_sk
        ) AS avg_return_for_reason
    FROM store_returns sr
    JOIN recent_reasons r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
) AS combined
ORDER BY reason, return_amount DESC
LIMIT 100
