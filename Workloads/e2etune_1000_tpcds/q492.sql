WITH sales_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        i.i_category,
        i.i_brand,
        t.t_hour,
        t.t_shift,
        cd_bill.cd_gender AS bill_gender,
        cd_bill.cd_education_status AS bill_education,
        cd_ship.cd_gender AS ship_gender,
        cd_ship.cd_marital_status AS ship_marital_status
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE
        i.i_category = 'Sports'
        AND cd_bill.cd_gender = 'F'
        AND cd_ship.cd_marital_status = 'M'
        AND t.t_hour BETWEEN 9 AND 17
        AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
)
SELECT
    i_category,
    bill_education,
    t_hour,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_quantity) AS avg_quantity,
    ROUND(SUM(ws_net_profit) / NULLIF(SUM(ws_net_paid), 0), 4) AS profit_margin,
    RANK() OVER (PARTITION BY t_hour ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_filtered
GROUP BY i_category, bill_education, t_hour
HAVING SUM(ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
