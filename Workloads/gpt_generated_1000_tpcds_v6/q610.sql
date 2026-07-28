WITH catalog_agg AS (
    SELECT
        td.t_hour AS hour_of_day,
        'catalog' AS source,
        SUM(cs.cs_net_profit) AS total_net_profit,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit_all
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND td.t_am_pm = 'PM'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_cost > 1000
      )
    GROUP BY td.t_hour
),
web_agg AS (
    SELECT
        td.t_hour AS hour_of_day,
        'web' AS source,
        SUM(ws.ws_net_profit) AS total_net_profit,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_net_profit_all
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE p.p_discount_active = 'Y'
      AND wp.wp_max_ad_count > 0
      AND td.t_am_pm = 'PM'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_cost > 1000
      )
    GROUP BY td.t_hour
)
SELECT hour_of_day,
       source,
       total_net_profit,
       avg_net_profit_all
FROM catalog_agg
WHERE total_net_profit > avg_net_profit_all
UNION ALL
SELECT hour_of_day,
       source,
       total_net_profit,
       avg_net_profit_all
FROM web_agg
WHERE total_net_profit > avg_net_profit_all
ORDER BY hour_of_day, source
