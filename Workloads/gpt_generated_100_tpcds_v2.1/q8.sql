SELECT
    ws.ws_order_number,
    ws.ws_ext_discount_amt,
    ws.ws_net_paid_inc_tax,
    sm.sm_carrier,
    sm.sm_contract,
    ws.ws_ext_discount_amt * ws.ws_quantity AS total_discount_amount
FROM web_sales ws
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'AIRBORNE'
  AND ws.ws_ext_discount_amt > 500
ORDER BY ws.ws_net_paid_inc_tax DESC
LIMIT 100
