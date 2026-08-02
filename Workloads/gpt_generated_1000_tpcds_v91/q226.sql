WITH cs_sample AS (
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_promo_sk,
           cs_call_center_sk,
           cs_net_profit,
           cs_ext_sales_price
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    d.d_year,
    p.p_promo_name,
    CASE
        WHEN i.i_current_price < 100 THEN 'Low'
        WHEN i.i_current_price BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS price_tier,
    min(regexp_extract(i.i_item_desc, '([A-Z]{3}[0-9]{2})', 1)) AS sample_item_code,
    count(DISTINCT i.i_item_sk) AS distinct_item_count,
    sum(cs.cs_net_profit) AS total_net_profit,
    sum(cs.cs_ext_sales_price) AS total_sales,
    CASE
        WHEN sum(cs.cs_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    min(concat(i.i_brand, ' ', i.i_product_name)) AS brand_product
FROM cs_sample cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE regexp_like(i.i_item_desc, '^[A-Z]{3}[0-9]{2}')
  AND i.i_product_name LIKE '%Pro%'
  AND p.p_promo_name LIKE '%Discount%'
  AND p.p_discount_active = 'Y'
  AND cc.cc_name LIKE 'Call%'
GROUP BY
    d.d_year,
    p.p_promo_name,
    CASE
        WHEN i.i_current_price < 100 THEN 'Low'
        WHEN i.i_current_price BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END
HAVING sum(cs.cs_net_profit) > 1000000
ORDER BY total_net_profit DESC
