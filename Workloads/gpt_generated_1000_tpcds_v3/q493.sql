WITH overall_avg AS (
    SELECT AVG(ws_net_profit) AS avg_profit
    FROM web_sales
)
SELECT
    site.web_name,
    wh.w_warehouse_name,
    wh.w_city,
    regexp_extract(wh.w_street_name, '^(\\w+)', 1) AS street_prefix,
    CONCAT(site.web_name, ' - ', wh.w_warehouse_name) AS combined_name,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_profit) AS avg_profit,
    substring(site.web_city, 1, 3) AS site_city_prefix
FROM web_sales ws
INNER JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
INNER JOIN warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
WHERE regexp_like(site.web_manager, '^R.*')
  AND wh.w_city LIKE '%Hill%'
GROUP BY
    site.web_name,
    wh.w_warehouse_name,
    wh.w_city,
    regexp_extract(wh.w_street_name, '^(\\w+)', 1),
    substring(site.web_city, 1, 3)
HAVING SUM(ws.ws_net_profit) > (SELECT avg_profit FROM overall_avg)
ORDER BY total_profit DESC
LIMIT 100
