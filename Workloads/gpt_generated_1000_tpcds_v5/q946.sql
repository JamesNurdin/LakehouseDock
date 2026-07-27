WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_item_sk
    FROM tpcds.catalog_page cp
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)legal|schools|classic')
      AND cp.cp_department LIKE 'DE%'
      AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
              AND cs2.cs_sales_price > 200
        )
)
SELECT
    cp_department,
    cp_type,
    CONCAT(cp_department, '_', SUBSTRING(cp_description, 1, 10)) AS dept_desc_snippet,
    COUNT(*) AS order_cnt,
    SUM(cs_ext_sales_price) AS total_ext_sales,
    AVG(cs_sales_price) AS avg_unit_price,
    CASE
        WHEN SUM(cs_net_profit) > 50000 THEN 'Profitable'
        ELSE 'Less Profitable'
    END AS profit_category,
    (SELECT AVG(cs_sales_price) FROM tpcds.catalog_sales) AS overall_avg_price,
    CASE
        WHEN AVG(cs_sales_price) > (SELECT AVG(cs_sales_price) FROM tpcds.catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS price_vs_overall,
    regexp_extract(cp_description, '(\\w+)', 1) AS first_word_desc
FROM page_sales
GROUP BY
    cp_department,
    cp_type,
    cp_description
HAVING COUNT(*) > 5
ORDER BY total_ext_sales DESC
LIMIT 100
