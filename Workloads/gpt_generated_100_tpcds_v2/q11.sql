WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_rows
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_description LIKE '%Legal%'
      AND cr.cr_return_ship_cost > 100
    GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_type
)
SELECT
    cp_department,
    cp_type,
    AVG(total_return_amount) AS avg_return_amount_per_page,
    SUM(total_return_quantity) AS total_quantity_across_pages,
    COUNT(*) AS number_of_pages
FROM page_returns
GROUP BY cp_department, cp_type
HAVING AVG(total_return_amount) > 200.0
ORDER BY avg_return_amount_per_page DESC
LIMIT 10
