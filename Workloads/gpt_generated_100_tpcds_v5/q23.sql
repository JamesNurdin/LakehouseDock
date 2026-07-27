WITH damaged_returns AS (
    SELECT
        cp.cp_type AS catalog_page_type,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY cp.cp_type, r.r_reason_desc
),
    dissatisfaction_returns AS (
    SELECT
        cp.cp_type AS catalog_page_type,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Customer Dissatisfaction'
    GROUP BY cp.cp_type, r.r_reason_desc
)
SELECT
    catalog_page_type,
    reason,
    total_return_amount,
    return_cnt
FROM damaged_returns
UNION ALL
SELECT
    catalog_page_type,
    reason,
    total_return_amount,
    return_cnt
FROM dissatisfaction_returns
ORDER BY catalog_page_type ASC, reason DESC
LIMIT 100
