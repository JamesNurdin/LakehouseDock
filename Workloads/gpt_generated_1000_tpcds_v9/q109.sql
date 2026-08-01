WITH store_aggs AS (
    SELECT
        p.p_promo_name,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
    GROUP BY p.p_promo_name
),
web_aggs AS (
    SELECT
        p.p_promo_name,
        sm.sm_type AS sales_channel,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
      AND p.p_channel_radio = 'N'
    GROUP BY p.p_promo_name, sm.sm_type
)
SELECT DISTINCT
    promo_name,
    sales_channel,
    net_paid,
    net_profit,
    distinct_metric
FROM (
    SELECT
        p_promo_name AS promo_name,
        sales_channel,
        net_paid,
        net_profit,
        distinct_tickets AS distinct_metric
    FROM store_aggs
    UNION ALL
    SELECT
        p_promo_name AS promo_name,
        sales_channel,
        net_paid,
        net_profit,
        distinct_orders AS distinct_metric
    FROM web_aggs
) combined
WHERE net_paid > 10000
ORDER BY net_paid DESC
LIMIT 100
