WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_catalog_page_sk,
        i.i_category,
        i.i_item_desc,
        i.i_product_name,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '.*[A-Z]{3}[0-9]{2}.*')
      AND i.i_units LIKE 'Each%'
)
SELECT
    COALESCE(fs.i_category, 'All Categories') AS category,
    COALESCE(CAST(fs.d_month_seq AS VARCHAR), 'All Months') AS month_seq,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    SUM(fs.cs_quantity) AS total_quantity,
    CASE WHEN SUM(fs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Medium' END AS sales_level
FROM filtered_sales fs
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_sk = fs.cs_catalog_page_sk
      AND regexp_like(cp.cp_description, concat('.*', substr(fs.i_item_desc, 1, 3), '.*'))
)
GROUP BY ROLLUP (fs.i_category, fs.d_month_seq)
HAVING SUM(fs.cs_ext_sales_price) > 0
ORDER BY category, month_seq
LIMIT 100
