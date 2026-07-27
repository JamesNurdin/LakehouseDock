WITH page_filtered AS (
    SELECT
        cp_catalog_page_sk,
        cp_department,
        cp_type,
        regexp_extract(cp_catalog_page_id, '(\\d+)$', 1) AS page_id_suffix,
        substring(cp_description, 1, 30) AS short_desc,
        CONCAT(cp_department, '-', cp_type) AS dept_type_concat
    FROM catalog_page
    WHERE cp_description LIKE '%sale%'
      AND regexp_like(cp_type, '^(PROMO|STANDARD)$')
)
SELECT
    pf.dept_type_concat,
    pf.page_id_suffix,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_returning_hdemo_sk) AS distinct_households,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(*) AS total_returns
FROM page_filtered pf
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = pf.cp_catalog_page_sk
WHERE cr.cr_store_credit > 10.00
GROUP BY pf.dept_type_concat, pf.page_id_suffix
ORDER BY total_return_amount DESC
LIMIT 100
