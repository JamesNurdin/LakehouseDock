SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    sm.sm_type AS ship_type,
    cd_bill.cd_education_status AS education_status,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    AVG(hd_ship.hd_vehicle_count) AS avg_vehicle_count
FROM web_sales ws
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE cd_bill.cd_education_status IN ('College', '4 yr Degree')
  AND cd_bill.cd_marital_status = 'M'
  AND ib.ib_lower_bound >= 50000
  AND sm.sm_contract = 'Y'
  AND ws.ws_quantity > 1
  AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  AND hd_ship.hd_vehicle_count >= 2
GROUP BY sm.sm_ship_mode_id, sm.sm_type, cd_bill.cd_education_status
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY profit_margin DESC
LIMIT 10
