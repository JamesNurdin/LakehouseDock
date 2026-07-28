WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_catalog_page_id,
        cp_description,
        cp_department,
        cp_type,
        CONCAT(cp_department, '-', cp_type) AS page_tag
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)national')
      AND cp_catalog_page_id LIKE 'AAAA%'
)
SELECT
    fp.cp_catalog_page_id,
    fp.page_tag,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    AVG(cs.cs_quantity) AS avg_quantity
FROM filtered_pages fp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY fp.cp_catalog_page_id, fp.page_tag
ORDER BY total_sales DESC
LIMIT 100
