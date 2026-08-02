WITH first_set AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_code,
        substring(i.i_product_name, 1, 10) AS product_prefix,
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '\\d+')
      AND i.i_brand LIKE 'A%'
      AND d.d_holiday = 'N'
    GROUP BY
        d.d_year,
        i.i_brand,
        regexp_extract(i.i_product_name, '(\\d+)', 1),
        substring(i.i_product_name, 1, 10),
        CONCAT(i.i_brand, '-', i.i_category)
),
second_set AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_code,
        substring(i.i_product_name, 1, 10) AS product_prefix,
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '(?i)coffee')
      AND i.i_brand LIKE '%B%'
      AND d.d_current_year = 'Y'
    GROUP BY
        d.d_year,
        i.i_brand,
        regexp_extract(i.i_product_name, '(\\d+)', 1),
        substring(i.i_product_name, 1, 10),
        CONCAT(i.i_brand, '-', i.i_category)
)
SELECT year, brand, product_code, product_prefix, brand_category, total_profit, avg_discount
FROM first_set
UNION
SELECT year, brand, product_code, product_prefix, brand_category, total_profit, avg_discount
FROM second_set
ORDER BY total_profit DESC
LIMIT 100
