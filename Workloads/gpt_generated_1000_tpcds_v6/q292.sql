WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND regexp_like(d.d_day_name, '^S')
)
SELECT
    i.i_category,
    i.i_category_id,
    p.p_promo_name,
    COUNT(*) AS sales_cnt,
    SUM(fs.cs_quantity) AS total_qty,
    SUM(fs.cs_net_profit) AS total_profit,
    AVG(fs.cs_net_profit) AS avg_profit,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    MAX(fs.cs_ext_sales_price) AS max_sales_price,
    CONCAT('Promo_', SUBSTRING(p.p_promo_name FROM 1 FOR 10)) AS promo_tag
FROM filtered_sales fs
JOIN item i ON fs.cs_item_sk = i.i_item_sk
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
WHERE i.i_product_name LIKE '%Organic%'
  AND regexp_like(p.p_promo_name, 'Discount[0-9]+')
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_net_profit > 1000
    )
GROUP BY
    i.i_category,
    i.i_category_id,
    p.p_promo_name
HAVING SUM(fs.cs_net_profit) > (
        SELECT AVG(cs3.cs_net_profit)
        FROM catalog_sales cs3
    )
ORDER BY total_profit DESC
LIMIT 100
