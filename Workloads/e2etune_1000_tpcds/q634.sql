WITH item_promo_stats AS (
    SELECT
        p_item_sk,
        COUNT(*) AS promo_cnt,
        SUM(p_cost) AS total_cost,
        AVG(p_cost) AS avg_cost,
        MIN(p_start_date_sk) AS min_start_date,
        MAX(p_end_date_sk) AS max_end_date
    FROM promotion
    WHERE p_cost >= 500
    GROUP BY p_item_sk
),
channel_flags AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        p.p_promo_id,
        CASE WHEN p.p_channel_email = 'Y' THEN 'Email' END AS channel_email,
        CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' END AS channel_tv,
        CASE WHEN p.p_channel_radio = 'Y' THEN 'Radio' END AS channel_radio,
        CASE WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail' END AS channel_dmail,
        CASE WHEN p.p_channel_event = 'Y' THEN 'Event' END AS channel_event,
        CASE WHEN p.p_channel_demo = 'Y' THEN 'Demo' END AS channel_demo,
        CASE WHEN p.p_channel_press = 'Y' THEN 'Press' END AS channel_press,
        CASE WHEN p.p_channel_catalog = 'Y' THEN 'Catalog' END AS channel_catalog,
        p.p_cost,
        p.p_discount_active
    FROM promotion p
    WHERE p.p_cost >= 500
)
SELECT
    t.p_item_sk,
    t.promo_cnt,
    t.total_cost,
    t.avg_cost,
    t.p_promo_id,
    t.p_cost,
    t.p_discount_active,
    t.primary_channel
FROM (
    SELECT
        s.p_item_sk,
        s.promo_cnt,
        s.total_cost,
        s.avg_cost,
        cf.p_promo_id,
        cf.p_cost,
        cf.p_discount_active,
        COALESCE(
            cf.channel_email,
            cf.channel_tv,
            cf.channel_radio,
            cf.channel_dmail,
            cf.channel_event,
            cf.channel_demo,
            cf.channel_press,
            cf.channel_catalog
        ) AS primary_channel,
        ROW_NUMBER() OVER (PARTITION BY s.p_item_sk ORDER BY cf.p_cost DESC) AS rn
    FROM item_promo_stats s
    JOIN channel_flags cf
      ON s.p_item_sk = cf.p_item_sk
    WHERE cf.p_discount_active = 'Y'
) t
WHERE t.rn = 1
ORDER BY t.total_cost DESC, t.p_item_sk
LIMIT 50
