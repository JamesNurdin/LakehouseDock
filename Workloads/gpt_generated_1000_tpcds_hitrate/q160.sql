WITH ship_agg AS (
    SELECT
        sm.sm_code AS description,
        CASE WHEN sm.sm_type = 'OVERNIGHT' THEN 'Fast' ELSE 'Premium' END AS type,
        SUM(ws.ws_ext_sales_price) AS value1,
        SUM(ws.ws_net_profit) AS value2
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_tax > 50
      AND sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
    GROUP BY sm.sm_code, sm.sm_type
),
site_agg AS (
    SELECT
        ws_site.web_site_id AS description,
        CASE WHEN ws_site.web_state = 'CA' THEN 'West' ELSE 'Other' END AS type,
        COUNT(DISTINCT ws.ws_order_number) * 1.0 AS value1,
        AVG(ws.ws_ext_tax) AS value2
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_list_price BETWEEN 100 AND 200
      AND ws_site.web_state IS NOT NULL
    GROUP BY ws_site.web_site_id, ws_site.web_state
)
SELECT description, type, value1, value2
FROM ship_agg
UNION ALL
SELECT description, type, value1, value2
FROM site_agg
ORDER BY description, type
LIMIT 100
