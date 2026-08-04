WITH intersect_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_email = 'Y'
      AND sm.sm_carrier = 'MSC'
    INTERSECT
    SELECT ws2.ws_order_number
    FROM web_sales ws2
    JOIN warehouse w ON ws2.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND w.w_gmt_offset > -5
)
SELECT
    ws.ws_web_site_sk,
    ws.ws_order_number,
    COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY ws.ws_web_site_sk) AS distinct_orders_cnt,
    SUM(DISTINCT ws.ws_net_paid) OVER (PARTITION BY ws.ws_web_site_sk) AS distinct_net_paid_sum,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rank_per_site
FROM web_sales ws
JOIN intersect_orders io ON ws.ws_order_number = io.ws_order_number
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
WHERE site.web_state = 'CA'
ORDER BY ws.ws_web_site_sk, rank_per_site
