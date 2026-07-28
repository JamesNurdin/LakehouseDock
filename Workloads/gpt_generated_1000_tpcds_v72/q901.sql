WITH sales_promo AS (
    SELECT
        ws.ws_promo_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price > 5000
)
SELECT
    p_promo_id,
    'TV' AS channel_type,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM sales_promo
WHERE p_channel_tv = 'Y'
GROUP BY p_promo_id
UNION ALL
SELECT
    p_promo_id,
    'Email' AS channel_type,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM sales_promo
WHERE p_channel_email = 'Y'
GROUP BY p_promo_id
ORDER BY total_net_profit DESC
LIMIT 100
