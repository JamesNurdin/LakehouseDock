WITH high_price_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_channel_email AS channel_email,
        cd.cd_gender AS gender,
        'high' AS price_segment,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_list_price >= 100
    GROUP BY p.p_promo_id, p.p_channel_email, cd.cd_gender
),
low_price_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_channel_email AS channel_email,
        cd.cd_gender AS gender,
        'low' AS price_segment,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_list_price < 100
    GROUP BY p.p_promo_id, p.p_channel_email, cd.cd_gender
)
SELECT promo_id, channel_email, gender, price_segment, total_net_profit
FROM high_price_sales
UNION ALL
SELECT promo_id, channel_email, gender, price_segment, total_net_profit
FROM low_price_sales
ORDER BY price_segment, promo_id, channel_email, gender
LIMIT 100
