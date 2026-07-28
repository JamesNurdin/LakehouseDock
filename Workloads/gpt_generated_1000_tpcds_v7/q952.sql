SELECT
    cp.cp_department,
    cp.cp_type,
    concat(cp.cp_department, ': ', i.i_product_name) AS dept_product,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    COUNT(*) AS transaction_cnt
FROM
    catalog_sales cs
JOIN
    catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN
    date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND regexp_like(cp.cp_description, '(?i)sale')
    AND regexp_like(i.i_product_name, '^A.*Z$')
GROUP BY
    cp.cp_department,
    cp.cp_type,
    concat(cp.cp_department, ': ', i.i_product_name)
ORDER BY
    total_sales DESC
LIMIT 100
