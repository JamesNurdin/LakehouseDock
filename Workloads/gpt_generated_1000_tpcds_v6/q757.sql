WITH filtered AS (
    SELECT
        cp.cp_department AS cp_department,
        cp.cp_description AS cp_description,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_fee AS cr_fee,
        CASE WHEN cr.cr_fee > 50 THEN 'High' ELSE 'Low' END AS fee_category,
        regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)goods')
      AND cp.cp_description LIKE '%fields%'
)
SELECT
    cp_department,
    fee_category,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_fee) AS avg_fee,
    MIN(first_word) AS sample_first_word
FROM filtered
GROUP BY cp_department, fee_category
ORDER BY total_return_amount DESC
LIMIT 20
