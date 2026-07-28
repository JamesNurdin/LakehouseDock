WITH catalog_data AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450300
    GROUP BY sm.sm_ship_mode_id
),
web_data AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450300
    GROUP BY sm.sm_ship_mode_id
)
SELECT *
FROM (
    SELECT DISTINCT 'Catalog' AS channel, ship_mode_id, profit, quantity
    FROM catalog_data
    UNION ALL
    SELECT DISTINCT 'Web' AS channel, ship_mode_id, profit, quantity
    FROM web_data
) AS combined
ORDER BY profit DESC
LIMIT 100
