SELECT sm.sm_carrier,
       sm.sm_contract,
       COUNT(*) AS order_cnt,
       SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'FEDEX'
  AND ws.ws_ext_ship_cost > 2000
GROUP BY sm.sm_carrier, sm.sm_contract
ORDER BY total_profit DESC
LIMIT 10
