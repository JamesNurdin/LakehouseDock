WITH promo_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_channel_dmail,
        SUM(ws.ws_net_profit) AS promo_net_profit,
        SUM(ws.ws_quantity) AS promo_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_cnt
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        p.p_channel_dmail
)
SELECT
    pa.p_channel_dmail AS channel,
    AVG(pa.promo_net_profit) AS avg_net_profit_per_promo,
    SUM(pa.promo_net_profit) AS total_net_profit_all_promos,
    COUNT(*) AS promo_count
FROM promo_agg pa
WHERE pa.promo_net_profit > 10000
GROUP BY pa.p_channel_dmail
HAVING COUNT(*) >= 5
