WITH cs_agg AS (
    SELECT cs_promo_sk, SUM(cs_net_profit) AS catalog_profit
    FROM catalog_sales
    GROUP BY cs_promo_sk
),
ws_agg AS (
    SELECT ws_promo_sk, SUM(ws_net_profit) AS web_profit
    FROM web_sales
    GROUP BY ws_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_year,
    d_start.d_month_seq AS start_month_seq,
    COALESCE(cs.catalog_profit, 0) AS catalog_profit,
    COALESCE(ws.web_profit, 0) AS web_profit,
    COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) AS total_profit,
    p.p_cost,
    (COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0)) / p.p_cost AS roi
FROM promotion p
LEFT JOIN cs_agg cs ON p.p_promo_sk = cs.cs_promo_sk
LEFT JOIN ws_agg ws ON p.p_promo_sk = ws.ws_promo_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
WHERE p.p_cost > 0
  AND d_start.d_year >= 2000
ORDER BY roi DESC
LIMIT 10
