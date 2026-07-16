SELECT
    hd_bill.hd_income_band_sk AS buyer_income_band,
    sm.sm_contract AS ship_contract,
    hd_bill.hd_buy_potential AS buyer_buy_potential,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_quantity) AS total_quantity
FROM web_sales ws
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    hd_bill.hd_vehicle_count <= 2
    AND hd_ship.hd_buy_potential = '1001-5000'
    AND sm.sm_contract IN ('YvxVaJI10', '6Hzzp4JkzjqD8MGXLCDa')
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
GROUP BY
    hd_bill.hd_income_band_sk,
    sm.sm_contract,
    hd_bill.hd_buy_potential
HAVING
    SUM(ws.ws_net_profit) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
