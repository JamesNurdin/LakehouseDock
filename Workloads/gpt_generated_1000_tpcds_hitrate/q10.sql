WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)   -- sample 5% of rows for faster processing
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    cp.cp_description,
    p.p_channel_email,
    SUM(s.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    CONCAT('Promo_', SUBSTRING(p.p_promo_id, 1, 5)) AS promo_code_tag
FROM sampled_sales s
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    REGEXP_LIKE(p.p_promo_id, '^AAAAAAA[AE]')               -- promo ids starting with AAAAAAA followed by A or E
    AND cp.cp_description LIKE '%catalog%'                -- description contains the word 'catalog'
    AND p.p_channel_email IS NOT NULL                     -- ensure the email channel flag is present
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    cp.cp_description,
    p.p_channel_email,
    CONCAT('Promo_', SUBSTRING(p.p_promo_id, 1, 5))
ORDER BY total_net_profit DESC
LIMIT 100
