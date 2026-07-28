WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        r.r_reason_desc,
        s.s_store_name,
        i.i_product_name
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND s.s_store_name LIKE 'Store %'
)
SELECT
    fr.s_store_name,
    fr.r_reason_desc,
    concat(fr.s_store_name, ' | ', fr.r_reason_desc) AS store_reason,
    fr.i_product_name,
    SUM(fr.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count
FROM filtered_returns fr
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
    WHERE sr2.sr_store_sk = fr.sr_store_sk
      AND lower(r2.r_reason_desc) LIKE '%fraud%'
)
GROUP BY
    fr.s_store_name,
    fr.r_reason_desc,
    concat(fr.s_store_name, ' | ', fr.r_reason_desc),
    fr.i_product_name
ORDER BY total_return_amount DESC
LIMIT 100
