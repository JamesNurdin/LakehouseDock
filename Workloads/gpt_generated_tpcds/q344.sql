WITH order_data AS (
    SELECT
        ws_order_number,
        ws_net_profit,
        ws_bill_cdemo_sk,
        ws_ship_cdemo_sk,
        ws_bill_customer_sk,
        ws_ship_customer_sk
    FROM web_sales
    WHERE ws_net_profit > 0
)
SELECT
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    COUNT(DISTINCT od.ws_order_number) AS order_cnt,
    SUM(od.ws_net_profit) AS total_net_profit,
    AVG(od.ws_net_profit) AS avg_net_profit
FROM order_data od
JOIN customer c_bill
    ON od.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON od.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
    ON od.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON od.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE c_bill.c_birth_year >= 1970
  AND c_ship.c_birth_year >= 1970
GROUP BY cd_bill.cd_gender, cd_ship.cd_gender
ORDER BY total_net_profit DESC
LIMIT 10
