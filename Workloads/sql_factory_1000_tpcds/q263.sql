WITH web_agg AS (
    SELECT
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk
),
catalog_agg AS (
    SELECT
        cs.cs_promo_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
    CASE
        WHEN COALESCE(c.catalog_net_profit, 0) = 0 THEN NULL
        ELSE COALESCE(w.web_net_profit, 0) / COALESCE(c.catalog_net_profit, 0)
    END AS profit_ratio,
    DENSE_RANK() OVER (
        ORDER BY CASE
            WHEN COALESCE(c.catalog_net_profit, 0) = 0 THEN 0
            ELSE COALESCE(w.web_net_profit, 0) / COALESCE(c.catalog_net_profit, 0)
        END DESC
    ) AS ratio_rank
FROM promotion p
LEFT JOIN web_agg w ON p.p_promo_sk = w.ws_promo_sk
LEFT JOIN catalog_agg c ON p.p_promo_sk = c.cs_promo_sk
WHERE p.p_discount_active = 'Y'
ORDER BY ratio_rank
LIMIT 20
