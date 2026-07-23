WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        concat(i.i_brand, ' - ', i.i_category) AS brand_category,
        regexp_extract(i.i_product_name, '^([A-Za-z]+)', 1) AS product_prefix,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_net_profit) AS total_profit,
        sum(ss.ss_quantity) AS total_quantity,
        CASE 
            WHEN sum(ss.ss_net_profit) > 10000 THEN 'High'
            WHEN sum(ss.ss_net_profit) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_product_name LIKE '%Special%'
      AND regexp_like(i.i_product_name, '^[A-Z][a-z]+')
    GROUP BY d.d_year,
             i.i_category,
             i.i_brand,
             i.i_product_name,
             concat(i.i_brand, ' - ', i.i_category),
             regexp_extract(i.i_product_name, '^([A-Za-z]+)', 1)
)
SELECT
    d_year,
    i_category,
    i_brand,
    brand_category,
    product_prefix,
    total_sales,
    total_profit,
    profit_category,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
