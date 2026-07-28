WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        CONCAT(cp.cp_department, '-', cp.cp_type) AS dept_type,
        REGEXP_EXTRACT(cp.cp_description, '(\\d{4})', 1) AS desc_year
    FROM catalog_page AS cp
    WHERE REGEXP_LIKE(cp.cp_description, '[0-9]{4}')
      AND cp.cp_description LIKE '%special%'
)
SELECT
    d.d_year,
    fp.dept_type,
    fp.desc_year,
    COUNT(cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_sales
FROM filtered_pages AS fp
JOIN catalog_sales AS cs
    ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
JOIN date_dim AS d
    ON cs.cs_sold_date_sk = d.d_date_sk
GROUP BY d.d_year, fp.dept_type, fp.desc_year
ORDER BY total_net_paid DESC
LIMIT 100
