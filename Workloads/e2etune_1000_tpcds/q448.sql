WITH promo_sales AS (
    SELECT
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ws.ws_promo_sk
),
promo_with_channel AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        CASE
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
            WHEN p.p_channel_press = 'Y' THEN 'Press'
            WHEN p.p_channel_event = 'Y' THEN 'Event'
            ELSE 'Other'
        END AS primary_channel
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    pwc.p_promo_id,
    pwc.primary_channel,
    ps.total_net_profit,
    ps.total_quantity,
    ps.avg_discount,
    RANK() OVER (PARTITION BY pwc.primary_channel ORDER BY ps.total_net_profit DESC) AS channel_profit_rank,
    RANK() OVER (ORDER BY ps.total_net_profit DESC) AS overall_profit_rank
FROM promo_sales ps
JOIN promo_with_channel pwc
    ON ps.ws_promo_sk = pwc.p_promo_sk
ORDER BY overall_profit_rank
LIMIT 10
