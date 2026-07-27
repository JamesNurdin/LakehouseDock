WITH store_agg AS (
    SELECT
        td.t_hour AS hour,
        td.t_meal_time AS meal_time,
        p.p_promo_id AS promo_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_cnt,
        'store' AS channel
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND p.p_discount_active = 'Y'
    GROUP BY td.t_hour, td.t_meal_time, p.p_promo_id
),
web_agg AS (
    SELECT
        td.t_hour AS hour,
        td.t_meal_time AS meal_time,
        p.p_promo_id AS promo_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_cnt,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND p.p_discount_active = 'Y'
    GROUP BY td.t_hour, td.t_meal_time, p.p_promo_id
)
SELECT
    hour,
    meal_time,
    promo_id,
    total_net_profit,
    transaction_cnt,
    channel
FROM store_agg
UNION ALL
SELECT
    hour,
    meal_time,
    promo_id,
    total_net_profit,
    transaction_cnt,
    channel
FROM web_agg
ORDER BY hour, promo_id, channel
LIMIT 100
