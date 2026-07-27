WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_brand,
        i.i_category,
        i.i_size,
        i.i_item_desc,
        i.i_item_id,
        i.i_product_name,
        i.i_color
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
)
SELECT
    brand_category,
    size_group,
    AVG(CAST(discount_pct AS double)) AS avg_discount_pct,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit,
    COUNT(DISTINCT order_number) AS distinct_orders,
    CASE WHEN SUM(total_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_status
FROM (
    SELECT DISTINCT
        concat(substring(i_item_id, 1, 3), '-', i_brand) AS brand_category,
        CASE WHEN i_size LIKE 'large%' THEN 'Large' ELSE 'Other' END AS size_group,
        cs_ext_sales_price AS total_sales,
        cs_net_profit AS total_profit,
        cs_order_number AS order_number,
        regexp_extract(i_item_desc, '(\\d+)%', 1) AS discount_pct
    FROM joined_data
    WHERE regexp_like(i_item_desc, '(?i)premium')
      AND i_size LIKE 'large%'

    UNION ALL

    SELECT
        concat(substring(i_item_id, 1, 3), '-', i_brand) AS brand_category,
        CASE WHEN i_size LIKE 'small%' THEN 'Small' ELSE 'Other' END AS size_group,
        cs_ext_sales_price AS total_sales,
        cs_net_profit AS total_profit,
        cs_order_number AS order_number,
        regexp_extract(i_item_desc, '(\\d+)%', 1) AS discount_pct
    FROM joined_data
    WHERE i_product_name LIKE '%Pack%'
      AND regexp_like(i_color, 'Red|Blue')
      AND i_size LIKE 'small%'
) AS combined
GROUP BY
    brand_category,
    size_group
ORDER BY
    total_sales DESC
LIMIT 100
