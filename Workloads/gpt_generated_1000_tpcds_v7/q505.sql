WITH tv_promo AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        p.p_promo_name   AS promo_name,
        SUM(cs.cs_net_profit)      AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        'TV_PROMO'        AS source_flag
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_tv = 'Y'
    GROUP BY sm.sm_ship_mode_id, p.p_promo_name
),
air_non_tv AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        p.p_promo_name   AS promo_name,
        SUM(cs.cs_net_profit)      AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        'AIR_SHIP'        AS source_flag
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR' AND p.p_channel_tv = 'N'
    GROUP BY sm.sm_ship_mode_id, p.p_promo_name
),
combined AS (
    SELECT * FROM tv_promo
    UNION ALL
    SELECT * FROM air_non_tv
)
SELECT
    ship_mode_id,
    promo_name,
    total_net_profit,
    order_cnt,
    source_flag
FROM combined
ORDER BY total_net_profit DESC
