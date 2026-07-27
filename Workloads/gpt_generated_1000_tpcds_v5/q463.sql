WITH filtered_returns AS (
    SELECT
        cr.cr_catalog_page_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_time_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 20
)
SELECT
    cp.cp_department,
    cp.cp_type,
    regexp_extract(cp.cp_description, '(?i)(sale|clearance)', 1) AS matched_term,
    CONCAT(cp.cp_department, '-', cp.cp_type) AS dept_type,
    COUNT(*) AS total_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_return_qty
FROM filtered_returns fr
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
    ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE regexp_like(cp.cp_description, '(?i)discount|sale|clearance')
  AND cd.cd_education_status LIKE '%Degree%'
GROUP BY
    cp.cp_department,
    cp.cp_type,
    regexp_extract(cp.cp_description, '(?i)(sale|clearance)', 1),
    CONCAT(cp.cp_department, '-', cp.cp_type)
ORDER BY total_return_amount DESC
LIMIT 100
