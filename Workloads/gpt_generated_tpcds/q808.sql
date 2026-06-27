/*
  Demographic breakdown of web sales by billing and shipping gender & marital status.
  Shows total net paid, total profit, total discount, order count and discount rate
  for each combination of billing and shipping demographics.
*/
WITH sales_by_demo AS (
    SELECT
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        cd_bill.cd_marital_status AS bill_marital_status,
        cd_ship.cd_marital_status AS ship_marital_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    GROUP BY
        cd_bill.cd_gender,
        cd_ship.cd_gender,
        cd_bill.cd_marital_status,
        cd_ship.cd_marital_status
)
SELECT
    bill_gender,
    ship_gender,
    bill_marital_status,
    ship_marital_status,
    total_net_paid,
    total_profit,
    total_discount,
    order_cnt,
    CASE
        WHEN total_net_paid = 0 THEN 0
        ELSE total_discount / total_net_paid
    END AS discount_rate
FROM sales_by_demo
ORDER BY total_net_paid DESC
LIMIT 20
