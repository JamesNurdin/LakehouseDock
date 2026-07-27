WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type LIKE 'A%'
      AND regexp_like(cp.cp_description, '\\d{3}')
)
SELECT
    cp_department,
    cp_type,
    CONCAT(cp_department, '-', cp_type) AS dept_type,
    COUNT(DISTINCT cp_catalog_page_sk) AS distinct_pages,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    MAX(regexp_extract(cp_description, '(\\d{3})', 1)) AS extracted_code,
    CASE
        WHEN SUM(cs_ext_sales_price) > 100000 THEN 'HIGH'
        WHEN SUM(cs_ext_sales_price) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category
FROM page_sales
WHERE SUBSTRING(cp_description, 1, 5) LIKE 'Promo%'
GROUP BY cp_department, cp_type, CONCAT(cp_department, '-', cp_type)
HAVING COUNT(*) > 10 AND SUM(cs_net_profit) > 0
ORDER BY total_sales DESC
LIMIT 100
