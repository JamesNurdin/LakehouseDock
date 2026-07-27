WITH filtered_returns AS (
    SELECT
        d.d_year,
        cr.cr_return_amount,
        i.i_item_desc,
        cp.cp_department,
        cp.cp_type,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)electronics')
      AND r.r_reason_desc LIKE 'Not%'
)
SELECT
    d_year,
    COUNT(*) AS return_count,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT regexp_extract(i_item_desc, '(\\d+)', 1)) AS distinct_numeric_codes,
    CONCAT(cp_department, ' - ', cp_type) AS dept_type_pattern
FROM filtered_returns
GROUP BY d_year, cp_department, cp_type
ORDER BY d_year DESC, total_return_amount DESC
LIMIT 10
