WITH catalog_agg AS (
    SELECT d.d_year AS year,
           cc.cc_market_manager AS market_manager,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2015 AND 2016
    GROUP BY d.d_year, cc.cc_market_manager
),
web_agg AS (
    SELECT d.d_year AS year,
           ws_site.web_market_manager AS market_manager,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(*) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year BETWEEN 2015 AND 2016
    GROUP BY d.d_year, ws_site.web_market_manager
)
SELECT year,
       market_manager,
       total_net_profit,
       order_count,
       'catalog' AS source
FROM catalog_agg
UNION ALL
SELECT year,
       market_manager,
       total_net_profit,
       order_count,
       'web' AS source
FROM web_agg
ORDER BY year DESC, total_net_profit DESC
OFFSET 0
LIMIT 100
