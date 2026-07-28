SELECT
    w.web_name AS site_name,
    sm.sm_type AS ship_type,
    SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE w.web_market_manager = 'Jarvis Allen'
  AND sm.sm_contract LIKE 'I3u%'
  AND w.web_rec_start_date >= DATE '2020-01-01'
GROUP BY w.web_name, sm.sm_type

UNION ALL

SELECT
    w.web_name AS site_name,
    sm.sm_type AS ship_type,
    SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE w.web_market_manager = 'David Myers'
  AND sm.sm_contract LIKE 'OrDu%'
  AND w.web_rec_end_date IS NULL
GROUP BY w.web_name, sm.sm_type

ORDER BY total_profit DESC
LIMIT 100
