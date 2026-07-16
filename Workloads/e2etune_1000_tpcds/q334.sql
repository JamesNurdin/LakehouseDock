WITH aggregated AS (
    SELECT
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        cd_bill.cd_education_status AS bill_edu,
        cd_ship.cd_education_status AS ship_edu,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_profit) AS avg_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE cd_bill.cd_purchase_estimate >= 1500
      AND cd_ship.cd_purchase_estimate >= 1500
      AND cd_bill.cd_gender = 'F'
      AND cd_ship.cd_gender = 'M'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY cd_bill.cd_gender, cd_ship.cd_gender, cd_bill.cd_education_status, cd_ship.cd_education_status
    HAVING COUNT(*) >= 5
)
SELECT
    bill_gender,
    ship_gender,
    bill_edu,
    ship_edu,
    order_cnt,
    total_profit,
    avg_profit,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 50
