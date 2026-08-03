WITH sales_data AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        d.d_year,
        p.p_promo_name,
        cp.cp_description,
        REGEXP_EXTRACT(i.i_item_desc, '([A-Z]+)$', 1) AS desc_suffix
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND p.p_promo_name LIKE '%Clearance%'
      AND cp.cp_type = 'Online'
)
SELECT
    MAX(i_brand) AS i_brand,
    MAX(i_category) AS i_category,
    d_year,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt,
    CASE
        WHEN SUM(cs_ext_sales_price) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_level,
    MAX(desc_suffix) AS desc_suffix,
    AVG(cs_ext_sales_price) AS avg_price,
    CASE
        WHEN AVG(cs_ext_sales_price) > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS price_category
FROM sales_data
GROUP BY GROUPING SETS (
    (i_brand, d_year),
    (i_category, d_year)
)
ORDER BY total_sales DESC
LIMIT 50
