WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_ship_cost
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND td.t_time_id LIKE 'AAAAAAA_%'
      AND regexp_like(td.t_time_id, '^A{7}')
      AND td.t_minute % 5 = 0
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_channel_details, '(\\w+)', 1) AS first_word,
    MIN(substring(p.p_channel_details, 1, 20)) AS details_preview,
    COUNT(*) AS sales_cnt,
    SUM(fs.cs_net_profit) AS total_profit,
    AVG(fs.cs_ext_ship_cost) AS avg_ship_cost,
    CONCAT(p.p_promo_name, ' ', CAST(fs.cs_quantity AS varchar)) AS promo_qty_concat
FROM filtered_sales fs
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
WHERE regexp_like(p.p_channel_details, '\\bA\\w+')
  AND p.p_channel_tv LIKE 'N%'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_channel_details, '(\\w+)', 1),
    CONCAT(p.p_promo_name, ' ', CAST(fs.cs_quantity AS varchar))
ORDER BY total_profit DESC
LIMIT 100
