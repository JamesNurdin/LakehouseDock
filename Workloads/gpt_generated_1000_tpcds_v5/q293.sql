WITH avg_tax AS (
    SELECT avg(ws_ext_tax) AS avg_tax_val FROM web_sales
)
SELECT sm_type, w_city, total_profit
FROM (
    SELECT
        sm.sm_type AS sm_type,
        wh.w_city AS w_city,
        sum(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ws.ws_ship_date_sk BETWEEN 2451430 AND 2451640
      AND ws.ws_ext_tax > (SELECT avg_tax_val FROM avg_tax)
    GROUP BY sm.sm_type, wh.w_city
    UNION ALL
    SELECT
        sm2.sm_type AS sm_type,
        wh2.w_city AS w_city,
        sum(ws2.ws_net_profit) AS total_profit
    FROM web_sales ws2
    JOIN ship_mode sm2 ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse wh2 ON ws2.ws_warehouse_sk = wh2.w_warehouse_sk
    WHERE sm2.sm_code = 'AIR'
      AND wh2.w_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM web_sales ws3
          WHERE ws3.ws_warehouse_sk = ws2.ws_warehouse_sk
            AND ws3.ws_net_profit > 1000
      )
    GROUP BY sm2.sm_type, wh2.w_city
) combined
ORDER BY total_profit DESC
LIMIT 100
