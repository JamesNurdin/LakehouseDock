/*
  Analytical query: net profit and quantity broken down by the income‑band of the billing household
  and the income‑band of the shipping household.
*/
WITH ws_demo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        hd_bill.hd_income_band_sk AS bill_income_band_sk,
        hd_bill.hd_buy_potential   AS bill_buy_potential,
        hd_ship.hd_income_band_sk AS ship_income_band_sk,
        hd_ship.hd_buy_potential   AS ship_buy_potential
    FROM web_sales ws
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
),
ws_income AS (
    SELECT
        wd.ws_order_number,
        wd.ws_net_profit,
        wd.ws_quantity,
        ib_bill.ib_lower_bound AS bill_lower_bound,
        ib_bill.ib_upper_bound AS bill_upper_bound,
        ib_ship.ib_lower_bound AS ship_lower_bound,
        ib_ship.ib_upper_bound AS ship_upper_bound,
        wd.bill_buy_potential,
        wd.ship_buy_potential
    FROM ws_demo wd
    JOIN income_band ib_bill
        ON wd.bill_income_band_sk = ib_bill.ib_income_band_sk
    JOIN income_band ib_ship
        ON wd.ship_income_band_sk = ib_ship.ib_income_band_sk
)
SELECT
    bill_lower_bound,
    bill_upper_bound,
    ship_lower_bound,
    ship_upper_bound,
    COUNT(DISTINCT ws_order_number)                AS order_cnt,
    SUM(ws_quantity)                               AS total_quantity,
    SUM(ws_net_profit)                             AS total_net_profit,
    AVG(ws_net_profit)                             AS avg_net_profit_per_order
FROM ws_income
GROUP BY
    bill_lower_bound,
    bill_upper_bound,
    ship_lower_bound,
    ship_upper_bound
ORDER BY total_net_profit DESC
LIMIT 100
