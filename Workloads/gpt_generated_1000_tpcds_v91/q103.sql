SELECT
    ws.ws_order_number,
    ws.ws_sales_price,
    hd.hd_vehicle_count,
    hd.hd_buy_potential
FROM web_sales ws
JOIN household_demographics hd
    ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count = 2
  AND ws.ws_list_price > 100
LIMIT 100
