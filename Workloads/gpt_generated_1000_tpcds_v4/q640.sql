SELECT DISTINCT sm.sm_carrier, sm.sm_code
FROM tpcds.web_sales ws
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_list_price > 80.00
  AND ws.ws_ext_ship_cost < 500.00
ORDER BY sm.sm_carrier
LIMIT 100
