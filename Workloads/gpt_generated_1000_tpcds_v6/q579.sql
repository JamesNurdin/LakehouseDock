WITH ca_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wh.w_state AS location_desc,
        hd.hd_buy_potential,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles' ELSE 'Few Vehicles' END AS vehicle_category,
        (
            SELECT MAX(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
        ) AS max_site_profit,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE wh.w_state = 'CA'
      AND ws.ws_ext_list_price > 5000
),
air_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        sm.sm_type AS location_desc,
        hd.hd_buy_potential,
        CASE WHEN hd.hd_vehicle_count = 0 THEN 'No Vehicles' ELSE 'Has Vehicles' END AS vehicle_category,
        (
            SELECT MAX(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
        ) AS max_site_profit,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE sm.sm_type = 'AIR'
      AND ws.ws_ext_list_price BETWEEN 2000 AND 4000
)
SELECT * FROM ca_sales
UNION ALL
SELECT * FROM air_sales
ORDER BY profit_rank, ws_ext_sales_price DESC
