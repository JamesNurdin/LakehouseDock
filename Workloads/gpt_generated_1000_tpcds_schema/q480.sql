WITH sales_by_page AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_description,
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        sm.sm_code,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY cp.cp_catalog_page_sk
            ORDER BY SUM(cs.cs_ext_sales_price) DESC
        ) AS rank_in_page
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cp.cp_description, '[A-Za-z]{3}\\d{2}')
      AND i.i_product_name LIKE '% %'
      AND sm.sm_code = 'AIR'
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_description,
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        sm.sm_code
)
SELECT
    sbp.cp_department,
    sbp.cp_description,
    sbp.i_product_name,
    sbp.d_year,
    sbp.sm_code,
    sbp.total_sales,
    sbp.sales_cnt,
    extracted.year_extracted,
    SUBSTR(sbp.cp_description, 1, 10) AS desc_prefix,
    CONCAT(sbp.cp_department, '-', CAST(sbp.d_year AS VARCHAR)) AS dept_year
FROM sales_by_page sbp
CROSS JOIN LATERAL (
    SELECT regexp_extract(sbp.cp_description, '(\\d{4})', 1) AS year_extracted
) AS extracted
WHERE sbp.rank_in_page <= 3
ORDER BY sbp.cp_department, sbp.total_sales DESC
LIMIT 100
