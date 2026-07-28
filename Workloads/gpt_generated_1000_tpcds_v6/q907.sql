WITH high_value_customers AS (
    SELECT DISTINCT cr_returning_customer_sk
    FROM catalog_returns
    WHERE cr_return_amount > 1000
    UNION
    SELECT DISTINCT cr_returning_customer_sk
    FROM catalog_returns
    WHERE cr_return_quantity = 1
)
SELECT
    cc.cc_name,
    cc.cc_state,
    r.r_reason_desc,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    (SELECT COUNT(*) FROM reason r2 WHERE r2.r_reason_desc LIKE 'Did not%') AS total_reason_like_cnt
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    cc.cc_zip = '25709'
    AND cc.cc_country = 'United States'
    AND cp.cp_department = 'Electronics'
    AND cp.cp_catalog_number = 5
    AND r.r_reason_id = 'AAAAAAAAFAAAAAAA'
    AND cr.cr_return_amount BETWEEN 100 AND 5000
    AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
          AND cp2.cp_type = 'Online'
    )
    AND cr.cr_returning_customer_sk IN (SELECT cr_returning_customer_sk FROM high_value_customers)
GROUP BY
    cc.cc_name,
    cc.cc_state,
    r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
