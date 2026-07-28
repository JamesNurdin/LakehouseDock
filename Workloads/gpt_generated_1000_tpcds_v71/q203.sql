WITH returns_sales_high_value AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_amt > 500
      AND ws.ws_sales_price > 50
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk
),
returns_sales_high_ship AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_ship_cost > 400
      AND ws.ws_sales_price < 20
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk
)
SELECT
    order_number,
    sold_date_sk,
    total_return_amt,
    total_net_profit
FROM returns_sales_high_value
UNION ALL
SELECT
    order_number,
    sold_date_sk,
    total_return_amt,
    total_net_profit
FROM returns_sales_high_ship
ORDER BY total_return_amt DESC
LIMIT 100
