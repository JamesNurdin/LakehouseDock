SELECT *
FROM (
    SELECT
        w.web_country AS country,
        sm.sm_code   AS ship_mode,
        SUM(ws.ws_net_paid_inc_ship) AS total_paid
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
      AND w.web_country = 'United States'
    GROUP BY w.web_country, sm.sm_code

    UNION ALL

    SELECT
        w.web_country AS country,
        sm.sm_code   AS ship_mode,
        SUM(ws.ws_net_paid_inc_ship) AS total_paid
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'SEA'
      AND w.web_country = 'United States'
    GROUP BY w.web_country, sm.sm_code
) AS combined
ORDER BY total_paid DESC
LIMIT 100
