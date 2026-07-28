WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
        i.i_brand,
        i.i_color,
        substring(i.i_product_name, 1, 10) AS product_prefix,
        sum(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)large')
      AND p.p_promo_name LIKE '%Discount%'
    GROUP BY
        d.d_year,
        i.i_category,
        regexp_extract(i.i_item_desc, '(\\w+)', 1),
        i.i_brand,
        i.i_color,
        substring(i.i_product_name, 1, 10)
)
SELECT
    d_year,
    i_category,
    first_word,
    concat(i_brand, ' ', i_color) AS brand_color,
    product_prefix,
    total_sales,
    sum(total_sales) OVER (PARTITION BY i_category ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sales_agg
ORDER BY i_category, d_year DESC
LIMIT 100
