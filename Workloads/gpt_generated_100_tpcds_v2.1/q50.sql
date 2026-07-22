WITH filtered_returns AS (
    SELECT 
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_catalog_page_sk,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)color|model')
),
distinct_pages AS (
    SELECT DISTINCT
        cp.cp_catalog_page_sk,
        cp.cp_description,
        cp.cp_department
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%service%'
)
SELECT
    dp.cp_catalog_page_sk,
    dp.cp_department,
    dp.cp_description,
    regexp_extract(dp.cp_description, '(\\w+)', 1) AS first_word,
    CONCAT(dp.cp_department, ': ', regexp_extract(dp.cp_description, '(\\w+)', 1)) AS dept_first_word,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT fr.cr_item_sk) AS distinct_items_returned,
    CASE 
        WHEN SUM(fr.cr_return_amount) > 10000 THEN 'High'
        WHEN SUM(fr.cr_return_amount) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category
FROM distinct_pages dp
JOIN filtered_returns fr ON dp.cp_catalog_page_sk = fr.cr_catalog_page_sk
JOIN time_dim td ON fr.cr_returned_time_sk = td.t_time_sk
GROUP BY 
    dp.cp_catalog_page_sk,
    dp.cp_department,
    dp.cp_description,
    regexp_extract(dp.cp_description, '(\\w+)', 1),
    CONCAT(dp.cp_department, ': ', regexp_extract(dp.cp_description, '(\\w+)', 1))
ORDER BY total_return_amount DESC
LIMIT 100
