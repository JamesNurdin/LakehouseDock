WITH profit_orders AS (
    SELECT ws.ws_order_number,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE sm.sm_type = 'AIR'
      AND cd.cd_gender = 'F'
    GROUP BY ws.ws_order_number
    HAVING SUM(ws.ws_net_profit) > 1000
),
returned_orders AS (
    SELECT DISTINCT wr.wr_order_number AS ws_order_number
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
)
SELECT po.ws_order_number,
       po.total_profit
FROM profit_orders po
EXCEPT
SELECT ro.ws_order_number,
       CAST(NULL AS decimal(7,2)) AS total_profit
FROM returned_orders ro
ORDER BY total_profit DESC
LIMIT 100
