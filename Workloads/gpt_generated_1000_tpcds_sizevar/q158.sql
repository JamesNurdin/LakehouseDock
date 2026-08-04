WITH sales_by_item AS (
    SELECT
        i.i_category,
        i.i_brand,
        regexp_extract(i.i_item_desc, '(\\d{3})') AS three_digit_code,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
      AND i.i_brand LIKE 'A%'
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
    GROUP BY i.i_category, i.i_brand, regexp_extract(i.i_item_desc, '(\\d{3})')
)
SELECT
    concat(sbi.i_brand, ' - ', sbi.i_category) AS brand_category,
    sbi.three_digit_code,
    sbi.total_sales,
    sbi.total_profit,
    (SELECT avg(total_sales) FROM sales_by_item) AS avg_category_sales
FROM sales_by_item sbi
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    JOIN item i2 ON p.p_item_sk = i2.i_item_sk
    WHERE i2.i_category = sbi.i_category
      AND i2.i_brand = sbi.i_brand
      AND regexp_extract(i2.i_item_desc, '(\\d{3})') = sbi.three_digit_code
      AND p.p_discount_active = 'Y'
)
ORDER BY sbi.total_sales DESC
LIMIT 100
