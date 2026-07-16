SELECT
    d_return.d_date AS return_date,
    d_return.d_year,
    d_return.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    AVG(ws.ws_quantity) AS avg_ws_quantity,
    d_ship.d_day_name AS ship_day_name,
    SUM(ws.ws_ext_sales_price) FILTER (WHERE d_ship.d_year = d_return.d_year) AS sales_ship_same_year,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed,
    SUM(s.s_floor_space) AS total_floor_space_closed,
    MIN(s.s_rec_end_date) AS earliest_store_close_date
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year >= 2000
GROUP BY
    d_return.d_date,
    d_return.d_year,
    d_return.d_month_seq,
    d_ship.d_day_name
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY d_return.d_date DESC
LIMIT 200
