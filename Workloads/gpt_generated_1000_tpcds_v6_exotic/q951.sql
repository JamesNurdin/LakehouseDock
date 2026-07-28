WITH promo_item_sales AS (
    SELECT
        p.p_promo_name,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_brand, ' ', i.i_category) AS brand_category,
        REGEXP_EXTRACT(p.p_promo_id, '\\d+', 0) AS promo_numeric_id,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND p.p_channel_details LIKE '%email%'
      AND SUBSTRING(i.i_product_name, 1, 5) = 'Fresh'
    GROUP BY
        p.p_promo_name,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_brand, ' ', i.i_category),
        REGEXP_EXTRACT(p.p_promo_id, '\\d+', 0)
)
SELECT
    p_promo_name,
    i_item_id,
    i_product_name,
    brand_category,
    promo_numeric_id,
    total_sales
FROM promo_item_sales
ORDER BY total_sales DESC
LIMIT 10
