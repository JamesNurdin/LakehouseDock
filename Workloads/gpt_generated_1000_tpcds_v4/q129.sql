WITH brand_profit AS (
   SELECT i.i_brand AS category,
          'brand_profit' AS metric,
          SUM(ws.ws_net_profit) AS value,
          ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 8 AND 12
     AND i.i_color = 'pink'
     AND i.i_wholesale_cost > (SELECT AVG(i2.i_wholesale_cost) FROM item i2)
   GROUP BY i.i_brand
   HAVING SUM(ws.ws_net_profit) > 0
),
top_brand AS (
   SELECT category, metric, value
   FROM brand_profit
   WHERE rn <= 5
),
site_profit AS (
   SELECT ws.ws_web_site_sk AS site_sk,
          SUM(ws.ws_net_profit) AS value,
          ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
   FROM web_sales ws
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   WHERE w.web_state = 'CA'
     AND EXISTS (
         SELECT 1 FROM web_page wp
         WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
           AND wp.wp_type = 'home'
     )
   GROUP BY ws.ws_web_site_sk
   HAVING SUM(ws.ws_net_profit) > 0
),
top_site AS (
   SELECT site_sk, value
   FROM site_profit
   WHERE rn <= 5
)
SELECT DISTINCT category, metric, value
FROM (
   SELECT * FROM top_brand
   UNION ALL
   SELECT
       w.web_company_name AS category,
       'site_profit' AS metric,
       ts.value AS value
   FROM top_site ts
   JOIN web_site w ON ts.site_sk = w.web_site_sk
) combined
ORDER BY value DESC
LIMIT 100
