SELECT sm.sm_type, SUM(ws.ws_net_paid) AS total_net_paid FROM web_sales ws JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk WHERE ws.ws_sold_date_sk = 2451072 GROUP BY sm.sm_type
