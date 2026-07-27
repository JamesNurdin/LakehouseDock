SELECT
    t_cr.t_hour,
    c_ret.c_salutation,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM catalog_returns cr
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t_cr.t_time_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
WHERE t_cr.t_hour BETWEEN 9 AND 17
  AND cr.cr_return_ship_cost > 100
  AND c_ret.c_salutation = 'Mr.'
  AND ws.ws_quantity > 5
GROUP BY t_cr.t_hour, c_ret.c_salutation
ORDER BY total_return_amount DESC
LIMIT 100
