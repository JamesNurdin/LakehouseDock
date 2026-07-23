WITH filtered_sales AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        w.w_county,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_code,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_product_name, '(?i)blue')
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND w.w_county LIKE 'B%'
)
SELECT
    i_category,
    i_brand,
    d_year,
    w_county,
    product_code,
    concat(i_brand, '-', product_code) AS brand_product,
    sum(cs_net_paid) AS total_net_paid,
    sum(cs_net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY i_category, i_brand, d_year, w_county, product_code
HAVING sum(cs_net_paid) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
