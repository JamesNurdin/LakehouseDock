WITH filtered_sales AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cd_bill.cd_gender = 'M'
      AND cd_bill.cd_education_status = 'College'
      AND td.t_shift = 'Afternoon'
      AND ca_bill.ca_state = ca_ship.ca_state
)
SELECT
    ca_bill.ca_state AS bill_state,
    td.t_hour AS hour_of_day,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(*) AS order_count
FROM filtered_sales ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
GROUP BY ca_bill.ca_state, td.t_hour
ORDER BY total_net_profit DESC
LIMIT 20
