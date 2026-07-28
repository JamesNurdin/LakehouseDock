SELECT
    sm.sm_type,
    sm.sm_code,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM tpcds.web_sales ws
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_code = 'AIR'
  AND ws.ws_wholesale_cost > 30
GROUP BY sm.sm_type, sm.sm_code
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
