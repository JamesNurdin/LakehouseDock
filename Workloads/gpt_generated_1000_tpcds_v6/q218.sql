WITH filtered_sales AS (
    SELECT 
        d.d_year,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND i.i_product_name LIKE '%air%'
      AND cc.cc_name LIKE '%Center%'
)
SELECT 
    d_year,
    concat(i_brand, ' ', i_product_name) AS brand_product,
    regexp_extract(i_item_desc, '(\\d{4})', 1) AS desc_year,
    sum(cs_ext_sales_price) AS total_sales,
    count(*) AS order_count
FROM filtered_sales
GROUP BY 
    d_year,
    concat(i_brand, ' ', i_product_name),
    regexp_extract(i_item_desc, '(\\d{4})', 1)
ORDER BY total_sales DESC
LIMIT 100
