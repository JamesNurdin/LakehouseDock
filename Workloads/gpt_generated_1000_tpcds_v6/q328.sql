WITH avg_return AS (
    SELECT AVG(cr_return_amount) AS avg_amt
    FROM catalog_returns
),
filtered_returns AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        r.r_reason_id,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '^Did not')
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
)
SELECT
    fr.r_reason_id || '_' || fr.r_reason_desc AS reason_key,
    regexp_extract(fr.r_reason_desc, '(Did not .*)', 1) AS extracted_phrase,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_net_loss) AS avg_net_loss
FROM filtered_returns fr
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_reason_sk = fr.cr_reason_sk
      AND cr2.cr_return_amount > fr.cr_return_amount
)
GROUP BY fr.r_reason_id, fr.r_reason_desc
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 10
