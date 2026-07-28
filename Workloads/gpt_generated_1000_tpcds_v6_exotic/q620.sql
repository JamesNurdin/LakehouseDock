WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        wp.wp_url,
        sm.sm_ship_mode_id,
        sm.sm_type,
        d.d_year,
        REGEXP_EXTRACT(wp.wp_url, '^https?://([^/]+)/', 1) AS domain
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type LIKE 'AIR%'
      AND REGEXP_LIKE(wp.wp_url, '^https?://[^/]*\\.com')
),
agg AS (
    SELECT
        ws_ship_mode_sk,
        sm_ship_mode_id,
        sm_type,
        domain,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        SUM(ws_net_profit) AS total_profit,
        (SELECT AVG(ws2.ws_net_profit)
         FROM web_sales ws2
         WHERE ws2.ws_ship_mode_sk = filtered_sales.ws_ship_mode_sk) AS avg_profit_by_ship_mode
    FROM filtered_sales
    GROUP BY ws_ship_mode_sk, sm_ship_mode_id, sm_type, domain
)
SELECT
    sm_ship_mode_id,
    sm_type,
    domain,
    order_cnt,
    total_profit,
    avg_profit_by_ship_mode,
    ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_profit DESC) AS rank_within_type
FROM agg
ORDER BY total_profit DESC
LIMIT 100
