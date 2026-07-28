WITH avg_profit_per_item AS (
    SELECT cs.cs_item_sk,
           AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT
    i.i_category,
    i.i_product_name,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(cs.cs_net_profit) > ap.avg_profit * 2 THEN 'High'
        WHEN SUM(cs.cs_net_profit) > ap.avg_profit      THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier,
    regexp_extract(i.i_item_desc, '(\\d{3,})', 1) AS extracted_code,
    CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN avg_profit_per_item ap ON cs.cs_item_sk = ap.cs_item_sk
WHERE regexp_like(i.i_item_desc, '[0-9]{3,}')
  AND p.p_promo_name LIKE 'Holiday%'
  AND (p.p_discount_active = 'Y' OR p.p_discount_active = 'N')
  AND EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_item_sk = cs.cs_item_sk
          AND ss.ss_net_paid > 1000
    )
GROUP BY
    i.i_category,
    i.i_product_name,
    p.p_promo_name,
    ap.avg_profit,
    i.i_item_desc,
    i.i_brand
ORDER BY total_profit DESC
LIMIT 100
