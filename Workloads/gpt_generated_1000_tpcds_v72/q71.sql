WITH store_profit AS (
   SELECT
       s.s_store_sk,
       s.s_store_name AS store_name,
       d.d_year,
       SUM(ss.ss_net_profit) AS total_net_profit,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year = 2022
     AND ss.ss_quantity > 0
     AND EXISTS (
         SELECT 1 FROM store_returns sr
         WHERE sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_return_quantity > 0
     )
   GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
web_profit AS (
   SELECT
       w.web_site_sk,
       w.web_name AS site_name,
       d.d_year,
       SUM(ws.ws_net_profit) AS total_net_profit,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS site_rank
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   WHERE d.d_year = 2022
     AND ws.ws_quantity > 0
     AND ws.ws_net_profit > 0
   GROUP BY w.web_site_sk, w.web_name, d.d_year
)
SELECT
    sp.store_rank AS rank,
    sp.store_name AS entity_name,
    sp.total_net_profit,
    'Store' AS entity_type,
    (SELECT AVG(total_net_profit) FROM (
        SELECT total_net_profit FROM store_profit
        UNION ALL
        SELECT total_net_profit FROM web_profit
    ) AS all_profit) AS avg_profit_across_entities
FROM store_profit sp
WHERE sp.store_rank <= 10
UNION ALL
SELECT
    wp.site_rank AS rank,
    wp.site_name AS entity_name,
    wp.total_net_profit,
    'WebSite' AS entity_type,
    (SELECT AVG(total_net_profit) FROM (
        SELECT total_net_profit FROM store_profit
        UNION ALL
        SELECT total_net_profit FROM web_profit
    ) AS all_profit) AS avg_profit_across_entities
FROM web_profit wp
WHERE wp.site_rank <= 10
ORDER BY rank, entity_type
LIMIT 100
