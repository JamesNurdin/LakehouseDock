WITH sales_2022 AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
)
SELECT
    cp.cp_catalog_page_id AS page_id,
    CONCAT(cp.cp_department, '_', cp.cp_type) AS dept_type,
    REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1) AS first_word,
    SUBSTRING(cp.cp_description FROM 1 FOR 10) AS desc_prefix,
    SUM(s.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT s.cs_item_sk) AS distinct_items_sold,
    COUNT(*) AS sales_transactions
FROM sales_2022 s
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    cp.cp_description LIKE '%funds%'
    AND REGEXP_LIKE(cp.cp_description, '[A-Za-z]{5,}')
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = s.cs_order_number
    )
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    cp.cp_description
ORDER BY total_net_paid DESC
LIMIT 100
