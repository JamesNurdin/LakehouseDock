WITH cr AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
        AND REGEXP_LIKE(CAST(cr.cr_return_amount AS VARCHAR), '^\\d+\\.\\d{2}$')
)
SELECT
    cp.cp_department AS department,
    sm.sm_type AS ship_type,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    COUNT(cr.cr_return_quantity) AS total_return_rows,
    REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1) AS first_word_description,
    CONCAT(cp.cp_department, '-', sm.sm_type) AS dept_ship_key
FROM catalog_page cp
FULL OUTER JOIN cr
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE (
        cp.cp_description IS NOT NULL AND REGEXP_LIKE(cp.cp_description, '\\d{3}')
    )
    OR (sm.sm_type IS NOT NULL AND sm.sm_type LIKE 'EXPRESS%')
    OR (cp.cp_catalog_page_sk IS NULL AND cr.cr_returned_date_sk IS NOT NULL)
GROUP BY
    cp.cp_department,
    sm.sm_type,
    cp.cp_description
ORDER BY
    total_return_amount DESC,
    department ASC
LIMIT 100
