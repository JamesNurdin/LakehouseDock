WITH filtered_catalog AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_description,
        i.i_category,
        i.i_product_name,
        d.d_year
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '[A-Z]{2}[0-9]{3}')
      AND cp.cp_type LIKE 'A%'
      AND i.i_item_desc LIKE '%steel%'
)
SELECT
    d_year,
    i_category,
    CONCAT(cp_department, ' - ', i_product_name) AS dept_product,
    SUBSTR(i_product_name, 1, 10) AS short_name,
    regexp_extract(cp_description, '([A-Z]{2}[0-9]{3})', 1) AS extracted_code,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_net_profit) AS avg_profit
FROM filtered_catalog
GROUP BY
    d_year,
    i_category,
    CONCAT(cp_department, ' - ', i_product_name),
    SUBSTR(i_product_name, 1, 10),
    regexp_extract(cp_description, '([A-Z]{2}[0-9]{3})', 1)
ORDER BY total_profit DESC
LIMIT 100
