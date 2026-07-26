WITH promo_store AS (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_quantity), 0) AS profit_per_unit,
        'store' AS channel
    FROM store_sales ss
    GROUP BY ss.ss_promo_sk
),
promo_web AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_quantity), 0) AS profit_per_unit,
        'web' AS channel
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk
),
promo_combined AS (
    SELECT
        COALESCE(promo_store.promo_sk, promo_web.promo_sk) AS promo_sk,
        COALESCE(promo_store.total_net_profit, 0) + COALESCE(promo_web.total_net_profit, 0) AS total_net_profit,
        COALESCE(promo_store.total_quantity, 0) + COALESCE(promo_web.total_quantity, 0) AS total_quantity,
        CASE
            WHEN (COALESCE(promo_store.total_net_profit, 0) + COALESCE(promo_web.total_net_profit, 0)) = 0 THEN 0
            ELSE (COALESCE(promo_store.total_net_profit, 0) + COALESCE(promo_web.total_net_profit, 0))
                 / NULLIF(COALESCE(promo_store.total_quantity, 0) + COALESCE(promo_web.total_quantity, 0), 0)
        END AS profit_per_unit,
        CASE
            WHEN COALESCE(promo_store.total_net_profit, 0) + COALESCE(promo_web.total_net_profit, 0) > 0 THEN 'Positive_Uplift'
            ELSE 'Negative_Uplift'
        END AS uplift_flag
    FROM promo_store
    FULL OUTER JOIN promo_web ON promo_store.promo_sk = promo_web.promo_sk
)
SELECT
    promo_sk,
    total_net_profit,
    total_quantity,
    profit_per_unit,
    uplift_flag,
    RANK() OVER (ORDER BY total_net_profit DESC) AS net_profit_rank,
    DENSE_RANK() OVER (ORDER BY profit_per_unit DESC) AS profit_per_unit_rank
FROM promo_combined
WHERE total_quantity > 0
ORDER BY net_profit_rank
LIMIT 20
