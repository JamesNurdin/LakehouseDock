WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit AS net_profit,
        p.p_promo_name AS promo_name,
        i.i_item_desc AS item_desc,
        regexp_extract(i.i_item_desc, '(?i)(blue|red|green|yellow)', 1) AS extracted_color,
        concat(p.p_promo_name, ' - ', regexp_extract(i.i_item_desc, '(?i)(blue|red|green|yellow)', 1)) AS promo_color,
        substring(i.i_item_desc, 1, 20) AS item_desc_prefix
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type LIKE 'quarter%'
      AND regexp_like(i.i_item_desc, '(?i)blue')
)
SELECT
    promo_color,
    extracted_color,
    item_desc_prefix,
    SUM(net_profit) AS total_profit,
    COUNT(*) AS sales_count
FROM filtered_sales
GROUP BY promo_color, extracted_color, item_desc_prefix
ORDER BY total_profit DESC
LIMIT 100
