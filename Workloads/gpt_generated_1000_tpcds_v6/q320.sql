WITH catalog_agg AS (
    SELECT
        p.p_promo_name AS promotion_name,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        'Catalog' AS sales_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450817 AND 2450830
    GROUP BY p.p_promo_name, sm.sm_type
),
web_agg AS (
    SELECT
        p.p_promo_name AS promotion_name,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        'Web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450817 AND 2450830
    GROUP BY p.p_promo_name, sm.sm_type
)
SELECT promotion_name, ship_mode_type, total_net_profit, sales_channel
FROM catalog_agg
UNION ALL
SELECT promotion_name, ship_mode_type, total_net_profit, sales_channel
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
