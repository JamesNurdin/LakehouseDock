WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        p.p_promo_name,
        i.i_brand,
        i.i_item_desc,
        i.i_color,
        REGEXP_EXTRACT(i.i_item_desc, '(?i)(discount).*', 1) AS extracted_word,
        CONCAT(p.p_promo_name, ' - ', i.i_brand) AS promo_brand
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_color LIKE 'pur%'
      AND REGEXP_LIKE(i.i_item_desc, '(?i)discount')
)
SELECT
    fs.cs_order_number,
    fs.p_promo_name,
    fs.i_brand,
    fs.extracted_word,
    fs.promo_brand,
    fs.cs_quantity,
    fs.cs_net_profit,
    SUM(fs.cs_net_profit) OVER (PARTITION BY fs.p_promo_name ORDER BY fs.cs_order_number ROWS UNBOUNDED PRECEDING) AS running_total_profit
FROM filtered_sales fs
ORDER BY fs.p_promo_name, fs.cs_order_number
OFFSET 0 LIMIT 100
