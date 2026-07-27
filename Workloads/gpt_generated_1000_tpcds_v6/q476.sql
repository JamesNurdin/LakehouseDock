WITH usps_warehouse_profit AS (
    SELECT
        w.w_city AS location,
        'USPS' AS source_type,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_carrier = 'USPS'
      AND sm.sm_contract = 'Ek'
    GROUP BY w.w_city
),
web_site_profit AS (
    SELECT
        ws_site.web_name AS location,
        'WebSite' AS source_type,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws_site.web_mkt_class LIKE '%Broad%'
      AND ws_site.web_class = 'Unknown'
    GROUP BY ws_site.web_name
)
SELECT location, source_type, total_profit
FROM usps_warehouse_profit
UNION ALL
SELECT location, source_type, total_profit
FROM web_site_profit
ORDER BY total_profit DESC
LIMIT 100
