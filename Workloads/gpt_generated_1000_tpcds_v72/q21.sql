-- Goal: Compare total catalog return amounts for 2000 by catalog department with those for 2001 by item category, restricting to returns that originated from promotional catalog pages. Include the overall average return amount as a reference value.

WITH avg_overall AS (
    SELECT AVG(cr2.cr_return_amt_inc_tax) AS avg_return_inc_tax
    FROM catalog_returns cr2
)
,
dept_returns AS (
    SELECT
        'department' AS src_type,
        cp.cp_department AS group_key,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        ao.avg_return_inc_tax
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    CROSS JOIN avg_overall ao
    WHERE d.d_year = 2000
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'promo'
        )
    GROUP BY cp.cp_department, ao.avg_return_inc_tax
)
,
category_returns AS (
    SELECT
        'category' AS src_type,
        i.i_category AS group_key,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        ao.avg_return_inc_tax
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    CROSS JOIN avg_overall ao
    WHERE d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'promo'
        )
    GROUP BY i.i_category, ao.avg_return_inc_tax
)

SELECT src_type,
       group_key,
       total_return_inc_tax,
       avg_return_inc_tax
FROM dept_returns
UNION ALL
SELECT src_type,
       group_key,
       total_return_inc_tax,
       avg_return_inc_tax
FROM category_returns
ORDER BY total_return_inc_tax DESC, src_type
LIMIT 100
