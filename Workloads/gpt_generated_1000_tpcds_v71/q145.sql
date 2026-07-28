WITH catalog_agg AS (
   SELECT
       p.p_promo_name AS promo_name,
       'Catalog' AS channel,
       SUM(cs.cs_net_profit) AS total_net_profit
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE p.p_channel_email = 'N'
     AND cc.cc_company_name LIKE 'pri%'
   GROUP BY p.p_promo_name
),
web_agg AS (
   SELECT
       p.p_promo_name AS promo_name,
       'Web' AS channel,
       SUM(ws.ws_net_profit) AS total_net_profit
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE p.p_channel_email = 'Y'
     AND wp.wp_image_count > 2
   GROUP BY p.p_promo_name
)
SELECT promo_name, channel, total_net_profit
FROM catalog_agg
UNION ALL
SELECT promo_name, channel, total_net_profit
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
