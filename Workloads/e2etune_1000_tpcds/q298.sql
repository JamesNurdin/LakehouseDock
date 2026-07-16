SELECT
    w.w_city,
    sm.sm_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM web_sales ws
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE cd_bill.cd_credit_rating = 'Good'
  AND cd_bill.cd_purchase_estimate >= 1500
  AND cd_ship.cd_marital_status IN ('M', 'S')
  AND sm.sm_type IN ('AIR', 'RAIL')
  AND w.w_state = 'CA'
GROUP BY w.w_city, sm.sm_type
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 20
