SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    d_return.d_date AS return_date,
    d_cust_first_sales.d_date AS first_sales_date,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_return_quantity) AS total_quantity_returned,
    SUM(wr.wr_net_loss) AS total_return_loss,
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_after_returns
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    d_sold.d_date,
    d_ship.d_date,
    d_return.d_date,
    d_cust_first_sales.d_date
ORDER BY net_profit_after_returns DESC
LIMIT 100
