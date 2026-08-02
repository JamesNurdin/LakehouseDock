WITH promo_channels AS (
    SELECT p_promo_sk FROM promotion WHERE p_channel_email = 'Y'
    UNION
    SELECT p_promo_sk FROM promotion WHERE p_channel_tv = 'Y'
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    w.w_warehouse_name,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = p.p_promo_sk) AS max_promo_cost,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_promo_sk = p.p_promo_sk) AS avg_web_profit_per_promo
FROM
    catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i TABLESAMPLE BERNOULLI (10) ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    p.p_end_date_sk BETWEEN 2450132 AND 2450646
    AND p.p_channel_dmail = 'Y'
    AND p.p_discount_active = 'Y'
    AND w.w_state = 'CA'
    AND i.inv_quantity_on_hand > 50
    AND ss.ss_addr_sk = 638239
    AND ss.ss_quantity > 2
    AND cs.cs_quantity > 5
    AND ws.ws_quantity > 3
    AND wp.wp_type = 'HOME'
    AND p.p_promo_sk IN (SELECT p_promo_sk FROM promo_channels)
    AND NOT EXISTS (
        SELECT 1 FROM promotion p_low
        WHERE p_low.p_promo_sk = p.p_promo_sk
          AND p_low.p_response_target < 1000
    )
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    w.w_warehouse_name,
    p.p_promo_sk
ORDER BY total_net_profit DESC
LIMIT 100
