WITH store_rev AS (
    SELECT d.d_year,
           s.s_country,
           SUM(ss.ss_net_paid) AS net_paid,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, s.s_country
), catalog_rev AS (
    SELECT d.d_year,
           cc.cc_country,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, cc.cc_country
), web_rev AS (
    SELECT d.d_year,
           wc.web_country,
           SUM(ws.ws_net_paid) AS net_paid,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wc ON ws.ws_web_site_sk = wc.web_site_sk
    GROUP BY d.d_year, wc.web_country
)
SELECT *
FROM (
    SELECT d_year,
           s_country AS country,
           net_paid,
           net_profit,
           'store' AS channel
    FROM store_rev
    UNION ALL
    SELECT d_year,
           cc_country AS country,
           net_paid,
           net_profit,
           'catalog' AS channel
    FROM catalog_rev
    UNION ALL
    SELECT d_year,
           web_country AS country,
           net_paid,
           net_profit,
           'web' AS channel
    FROM web_rev
) t
WHERE net_paid > 0
ORDER BY d_year, net_paid DESC
LIMIT 100
