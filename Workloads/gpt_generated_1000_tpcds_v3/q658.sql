WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name,
        c.c_email_address,
        d.d_year
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND i.i_item_desc IS NOT NULL
      AND regexp_like(i.i_item_desc, '\\d{4}')
      AND i.i_product_name LIKE 'A%'
      AND c.c_email_address LIKE '%@example.com'
),
brand_aggregated AS (
    SELECT
        i_brand,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count,
        MIN(regexp_extract(i_item_desc, '(\\d{4})', 1)) AS example_code,
        MIN(substr(i_item_desc, 1, 10)) AS desc_prefix
    FROM filtered_sales
    GROUP BY i_brand
)
SELECT
    ba.i_brand,
    ba.total_net_profit,
    ba.sales_count,
    ba.example_code,
    ba.desc_prefix,
    concat('Brand_', ba.i_brand) AS brand_concat,
    row_number() OVER (ORDER BY ba.total_net_profit DESC) AS brand_rank
FROM brand_aggregated ba
WHERE ba.total_net_profit > (
    SELECT AVG(total_net_profit) FROM brand_aggregated
)
ORDER BY brand_rank
LIMIT 100
