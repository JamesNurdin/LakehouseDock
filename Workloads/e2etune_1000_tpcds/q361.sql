WITH sales_returns AS (
    SELECT
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_ship_hdemo_sk AS ship_hdemo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amount
    FROM web_sales ws
    JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
       AND ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
      AND ws.ws_quantity > 0
    GROUP BY ws.ws_ship_mode_sk, ws.ws_ship_hdemo_sk
)
SELECT
    ship_mode_sk,
    ship_hdemo_sk,
    total_orders,
    total_sales,
    total_return_amount,
    total_return_quantity,
    total_net_profit,
    avg_coupon_amount,
    (total_return_amount / NULLIF(total_sales, 0)) * 100 AS return_rate_percent,
    RANK() OVER (ORDER BY (total_return_amount / NULLIF(total_sales, 0)) DESC) AS return_rate_rank
FROM sales_returns
ORDER BY return_rate_percent DESC
LIMIT 10
