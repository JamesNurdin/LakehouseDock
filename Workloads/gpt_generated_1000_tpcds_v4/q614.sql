SELECT
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_return_sum,
    MIN(cr.cr_return_tax) AS min_tax,
    MAX(cr.cr_return_tax) AS max_tax
FROM
    catalog_returns cr
JOIN
    reason r
      ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    cr.cr_return_quantity >= 2
    AND cr.cr_return_amount BETWEEN 10 AND 500
    AND r.r_reason_id IN ('AAAAAAAABBAAAAAA', 'AAAAAAAAMAAAAAAA')
    AND cr.cr_fee > 20
    AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_desc LIKE '%size%'
    )
GROUP BY
    r.r_reason_desc
HAVING
    COUNT(*) >= 5
ORDER BY
    total_return DESC
LIMIT 100
