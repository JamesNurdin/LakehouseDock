WITH ws_sold AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        d_sold.d_date,
        d_sold.d_year
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
)
SELECT
    w.w_warehouse_name,
    wp.wp_type,
    d_sold.d_year,
    SUM(ws_sold.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_sold.ws_order_number) AS order_cnt,
    AVG(ws_sold.ws_quantity) AS avg_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    MIN(ws_sold.ws_sales_price) AS min_sales_price,
    MAX(ws_sold.ws_sales_price) AS max_sales_price
FROM ws_sold
JOIN date_dim d_sold ON ws_sold.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws_sold.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON ws_sold.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws_sold.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws_sold.ws_item_sk
   AND wr.wr_order_number = ws_sold.ws_order_number
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_date >= DATE '2002-01-01'
  AND d_sold.d_date <= DATE '2002-01-31'
  AND w.w_city = 'San Francisco'
  AND wp.wp_type = 'home'
GROUP BY w.w_warehouse_name, wp.wp_type, d_sold.d_year
ORDER BY total_profit DESC
LIMIT 100
