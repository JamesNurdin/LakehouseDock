WITH sales_by_demo AS (
    SELECT
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_net_paid) AS total_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE ws.ws_quantity > 0
    GROUP BY cd_bill.cd_gender, cd_ship.cd_gender
)
SELECT
    bill_gender,
    ship_gender,
    total_profit,
    total_paid,
    total_quantity,
    avg_discount,
    total_profit / SUM(total_profit) OVER () AS profit_pct,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_by_demo
ORDER BY total_profit DESC
LIMIT 10
