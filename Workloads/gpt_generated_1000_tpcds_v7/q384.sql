WITH promo_active AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        p.p_promo_name    AS p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w  ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s    ON ws.ws_web_site_sk = s.web_site_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
    GROUP BY w.w_warehouse_name, p.p_promo_name
),
promo_inactive AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        p.p_promo_name    AS p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w  ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s    ON ws.ws_web_site_sk = s.web_site_sk
    WHERE p.p_discount_active = 'N'
      AND p.p_channel_catalog = 'Y'
    GROUP BY w.w_warehouse_name, p.p_promo_name
)
SELECT w_warehouse_name, p_promo_name, total_net_profit
FROM promo_active
UNION ALL
SELECT w_warehouse_name, p_promo_name, total_net_profit
FROM promo_inactive
ORDER BY w_warehouse_name, total_net_profit DESC
