WITH filtered_sales AS (
    SELECT
        cs.cs_ext_sales_price,
        i.i_brand,
        i.i_category,
        i.i_item_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2000
      AND regexp_like(i.i_brand, '^edu')
      AND i.i_brand LIKE '%pack%'
      AND regexp_like(p.p_promo_name, '.*discount.*')
)
SELECT
    concat(i_brand, ':', i_category) AS brand_category,
    sum(cs_ext_sales_price) AS total_sales,
    CASE WHEN sum(cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
FROM filtered_sales
GROUP BY concat(i_brand, ':', i_category)
HAVING sum(cs_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100
