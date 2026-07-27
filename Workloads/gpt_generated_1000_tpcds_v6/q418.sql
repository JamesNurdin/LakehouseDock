WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_catalog_page_id,
        cp_description,
        cp_catalog_number,
        cp_department
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)legal')
      AND cp_description LIKE '%funds%'
)
SELECT
    p.cp_catalog_page_id,
    p.cp_catalog_number,
    p.cp_department,
    regexp_extract(p.cp_description, '(\\w+)', 1) AS first_word,
    COUNT(r.cr_order_number) AS returns_cnt,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(r.cr_return_ship_cost) AS total_ship_cost
FROM filtered_pages p
JOIN catalog_returns r
    ON r.cr_catalog_page_sk = p.cp_catalog_page_sk
WHERE r.cr_call_center_sk IN (20, 22, 34)
GROUP BY
    p.cp_catalog_page_id,
    p.cp_catalog_number,
    p.cp_department,
    regexp_extract(p.cp_description, '(\\w+)', 1)
HAVING SUM(r.cr_return_amount) > 500
ORDER BY total_return_inc_tax DESC
LIMIT 100
