SELECT
    s.s_market_manager,
    i_sold.i_class,
    d_sold.d_year,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i_sold
  ON ws.ws_item_sk = i_sold.i_item_sk
JOIN item i_sold2
  ON ws.ws_item_sk = i_sold2.i_item_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN item i_return
  ON wr.wr_item_sk = i_return.i_item_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_extra
  ON ws.ws_sold_date_sk = d_extra.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY s.s_market_manager, i_sold.i_class, d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
