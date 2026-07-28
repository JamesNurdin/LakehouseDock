WITH filtered_sales AS (
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cp.cp_department,
        cp.cp_description,
        i.i_item_desc,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cp.cp_description LIKE '%New%'
      AND regexp_like(i.i_item_desc, '(?i)(TV|Camera)')
)
SELECT 
    concat(cp_department, '-', cast(d_year as varchar)) AS dept_year,
    d_year,
    cp_department,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    MAX(substring(i_item_desc, 1, 30)) AS sample_item_desc,
    CASE WHEN SUM(cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM filtered_sales
GROUP BY cp_department, d_year
HAVING SUM(cs_ext_sales_price) > 50000
ORDER BY total_sales DESC
