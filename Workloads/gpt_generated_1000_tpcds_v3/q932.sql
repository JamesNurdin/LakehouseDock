WITH store_sales_agg AS (
    SELECT s.s_store_id AS channel_id,
           'store' AS channel_type,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id
),
web_sales_agg AS (
    SELECT w.web_site_id AS channel_id,
           'web' AS channel_type,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
    GROUP BY w.web_site_id
),
combined AS (
    SELECT channel_id, channel_type, total_net_profit FROM store_sales_agg
    UNION ALL
    SELECT channel_id, channel_type, total_net_profit FROM web_sales_agg
)
SELECT c.channel_id,
       c.channel_type,
       c.total_net_profit
FROM combined c
WHERE c.total_net_profit > (
    SELECT AVG(inner_total) FROM (
        SELECT SUM(ss.ss_net_profit) AS inner_total
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
        GROUP BY ss.ss_store_sk
        UNION ALL
        SELECT SUM(ws.ws_net_profit) AS inner_total
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
        GROUP BY ws.ws_web_site_sk
    ) avg_sub
)
ORDER BY c.total_net_profit DESC
LIMIT 100
