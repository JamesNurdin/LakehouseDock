WITH catalog_part AS (
    SELECT
        'catalog' AS sales_channel,
        cs.cs_sold_date_sk AS sold_date_sk,
        cp.cp_department AS category,
        sm.sm_ship_mode_id AS ship_mode_id,
        p.p_promo_name AS promo_name,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        (
            SELECT AVG(cs3.cs_net_profit)
            FROM catalog_sales cs3
            JOIN promotion p3 ON cs3.cs_promo_sk = p3.p_promo_sk
            WHERE p3.p_discount_active = 'Y'
        ) AS avg_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE sm.sm_contract = 'OrDuVy2H'
      AND p.p_channel_email = 'Y'
),
web_part AS (
    SELECT
        'web' AS sales_channel,
        ws.ws_sold_date_sk AS sold_date_sk,
        wp.wp_type AS category,
        sm.sm_ship_mode_id AS ship_mode_id,
        p.p_promo_name AS promo_name,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        (
            SELECT AVG(ws3.ws_net_profit)
            FROM web_sales ws3
            JOIN promotion p3 ON ws3.ws_promo_sk = p3.p_promo_sk
            WHERE p3.p_discount_active = 'Y'
        ) AS avg_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE wp.wp_char_count > 2000
      AND p.p_channel_email = 'Y'
)
SELECT *
FROM catalog_part
UNION ALL
SELECT *
FROM web_part
ORDER BY net_paid DESC
LIMIT 100
