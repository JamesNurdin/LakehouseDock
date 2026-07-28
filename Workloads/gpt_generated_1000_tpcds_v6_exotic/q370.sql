WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        i.i_item_desc,
        i.i_product_name,
        p.p_promo_name,
        d.d_year,
        regexp_extract(i.i_item_desc, '([0-9]{3})', 1) AS extracted_code
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{2}[0-9]{3}\\b')
      AND i.i_item_desc LIKE '%PRO%'
      AND d.d_year = 2001
)
SELECT
    p.p_promo_name,
    CASE
        WHEN SUM(fs.cs_ext_discount_amt) > 5000 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_level,
    COUNT(*) AS sales_cnt,
    SUM(fs.cs_net_profit) AS total_profit,
    CONCAT(p.p_promo_name, '_', SUBSTRING(i.i_product_name, 1, 5)) AS promo_product_key,
    MAX(fs.extracted_code) AS sample_item_code
FROM filtered_sales fs
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
JOIN item i ON fs.cs_item_sk = i.i_item_sk
GROUP BY p.p_promo_name,
         CONCAT(p.p_promo_name, '_', SUBSTRING(i.i_product_name, 1, 5))
ORDER BY total_profit DESC
LIMIT 20
