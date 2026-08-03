WITH overall_avg_return AS (
    SELECT AVG(cr_return_amount) AS avg_amount
    FROM catalog_returns
)
SELECT
    cc.cc_name,
    cp.cp_department,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    CASE
        WHEN SUM(cr.cr_return_amount) > (SELECT avg_amount FROM overall_avg_return) THEN 'above_avg'
        ELSE 'below_avg'
    END AS return_category,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM catalog_returns AS cr
JOIN call_center AS cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page AS cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cc.cc_class = 'large'
  AND cc.cc_tax_percentage >= 0.09
  AND cp.cp_catalog_number IN (11, 14)
  AND cr.cr_return_amount > 30
GROUP BY
    cc.cc_name,
    cp.cp_department
ORDER BY total_return_amount DESC
LIMIT 100
