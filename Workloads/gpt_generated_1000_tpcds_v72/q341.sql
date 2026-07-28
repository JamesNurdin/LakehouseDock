WITH sales_summary AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_description,
        CONCAT(cp.cp_department, '-', CAST(cp.cp_catalog_number AS VARCHAR)) AS page_label,
        REGEXP_EXTRACT(cp.cp_description, '(\\d{3})') AS extracted_code,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND REGEXP_LIKE(cp.cp_description, '(?i)discount')
      AND cp.cp_type LIKE 'C%'
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_description,
        CONCAT(cp.cp_department, '-', CAST(cp.cp_catalog_number AS VARCHAR)),
        REGEXP_EXTRACT(cp.cp_description, '(\\d{3})')
)
SELECT
    ss.page_label,
    ss.cp_description,
    ss.extracted_code,
    ss.total_sales,
    ss.order_cnt
FROM sales_summary ss
ORDER BY ss.total_sales DESC
LIMIT 100
