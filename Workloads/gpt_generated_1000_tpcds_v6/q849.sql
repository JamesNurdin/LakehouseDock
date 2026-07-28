WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_department,
        cp_catalog_page_number,
        cp_description,
        cp_type,
        CONCAT(cp_department, '-', CAST(cp_catalog_page_number AS VARCHAR)) AS dept_page_key,
        regexp_extract(cp_description, '(\\d{4})') AS extracted_year
    FROM tpcds.catalog_page
    WHERE regexp_like(cp_description, '.*[0-9]{4}.*')
      AND cp_type LIKE 'A%'
),
agg_sales AS (
    SELECT
        fp.cp_department,
        fp.cp_type,
        fp.dept_page_key,
        fp.extracted_year,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM filtered_pages fp
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
    WHERE cs.cs_sold_time_sk BETWEEN 40000 AND 80000
    GROUP BY
        fp.cp_department,
        fp.cp_type,
        fp.dept_page_key,
        fp.extracted_year
    HAVING SUM(cs.cs_ext_sales_price) > 100000
)
SELECT
    cp_department,
    cp_type,
    order_cnt,
    total_sales,
    avg_discount,
    dept_page_key,
    extracted_year,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS dept_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
