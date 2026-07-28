WITH catalog_agg AS (
    SELECT
        p.p_promo_name,
        'catalog' AS sales_channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count,
        (SELECT MIN(p2.p_start_date_sk) FROM promotion p2 WHERE p2.p_promo_name = p.p_promo_name) AS promo_start_date_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_end_date_sk >= 2450592
      AND cs.cs_quantity > 2
      AND EXISTS (
          SELECT 1 FROM store_sales ss
          WHERE ss.ss_promo_sk = p.p_promo_sk
            AND ss.ss_sales_price > 20
      )
    GROUP BY p.p_promo_name
),
store_agg AS (
    SELECT
        p.p_promo_name,
        'store' AS sales_channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count,
        (SELECT MIN(p2.p_start_date_sk) FROM promotion p2 WHERE p2.p_promo_name = p.p_promo_name) AS promo_start_date_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_end_date_sk BETWEEN 2450132 AND 2450712
      AND ss.ss_quantity >= 1
    GROUP BY p.p_promo_name
)
SELECT *
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
) AS combined
ORDER BY combined.total_net_profit DESC
LIMIT 100
