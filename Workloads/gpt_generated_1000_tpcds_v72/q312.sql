WITH filtered_returns AS (
    SELECT
        cr.cr_catalog_page_sk,
        cr.cr_return_amount,
        cr.cr_reason_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(CAST(cr.cr_return_amount AS varchar), '^\\d+\\.\\d{2}$')
      AND cr.cr_return_amount > 0
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1) AS first_word,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(fr.cr_return_amount) > 5000 THEN 'High'
        WHEN SUM(fr.cr_return_amount) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level
FROM filtered_returns fr
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
WHERE LOWER(cp.cp_description) LIKE '%clearance%'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
          AND REGEXP_LIKE(r2.r_reason_desc, '^Customer.*')
    )
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_description,
    REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1)
ORDER BY total_return_amount DESC
LIMIT 100
