WITH catalog_part AS (
    SELECT DISTINCT
        sm.sm_ship_mode_id,
        cs.cs_net_paid_inc_ship
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_zip LIKE '3%'
      AND sm.sm_type = 'AIR'
      AND cs.cs_net_paid_inc_ship > 1000
),
web_part AS (
    SELECT DISTINCT
        sm.sm_ship_mode_id,
        ws.ws_net_paid_inc_ship
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE site.web_city = 'San Jose'
      AND site.web_rec_end_date >= DATE '2000-01-01'
      AND sm.sm_type = 'AIR'
)
SELECT
    ship_mode_id,
    SUM(net_paid) AS total_net_paid
FROM (
    SELECT sm_ship_mode_id AS ship_mode_id, cs_net_paid_inc_ship AS net_paid
    FROM catalog_part
    UNION ALL
    SELECT sm_ship_mode_id AS ship_mode_id, ws_net_paid_inc_ship AS net_paid
    FROM web_part
) combined
GROUP BY ship_mode_id
ORDER BY total_net_paid DESC
