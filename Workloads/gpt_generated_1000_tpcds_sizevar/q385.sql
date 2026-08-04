WITH agg AS (
    SELECT
        MIN(i.i_item_sk) AS i_item_sk,
        MIN(i.i_category) AS i_category,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        MAX(regexp_extract(i.i_product_name, '([A-Z]+)', 1)) AS product_code,
        MAX(CASE WHEN regexp_like(i.i_brand, '^B.*') THEN 'B-brand' ELSE 'Other' END) AS brand_group
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_item_desc LIKE '%dress%'
      AND regexp_like(i.i_item_desc, '.*[0-9]{2}.*')
    GROUP BY GROUPING SETS (
        (i.i_item_sk, i.i_category, d.d_year),
        (i.i_category, d.d_year),
        (d.d_year)
    )
)
SELECT
    agg.i_item_sk,
    agg.i_category,
    agg.d_year,
    agg.total_sales,
    agg.order_cnt,
    agg.product_code,
    agg.brand_group,
    (SELECT SUM(cr.cr_return_amount)
     FROM catalog_returns cr
     WHERE cr.cr_item_sk = agg.i_item_sk) AS total_returns
FROM agg
ORDER BY agg.total_sales DESC
LIMIT 100
