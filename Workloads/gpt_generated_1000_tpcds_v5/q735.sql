WITH store_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_ext_discount_amt > 500
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
),
web_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category
    FROM tpcds.web_sales ws
    JOIN tpcds.household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ws.ws_ext_discount_amt > 500
      AND sm.sm_type = 'AIR'
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_profit DESC
LIMIT 100
