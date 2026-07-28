WITH filtered AS (
    SELECT
        d.d_year,
        r.r_reason_desc,
        cp.cp_department,
        cp.cp_type,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '\\d{4}')
      AND cp.cp_type LIKE '%online%'
)
SELECT
    d_year,
    r_reason_desc,
    concat(cp_department, '-', cp_type) AS dept_type,
    avg(cr_return_amount) AS avg_return_amount,
    count(*) AS return_count
FROM filtered
GROUP BY
    d_year,
    r_reason_desc,
    concat(cp_department, '-', cp_type)
ORDER BY
    d_year,
    avg_return_amount DESC
