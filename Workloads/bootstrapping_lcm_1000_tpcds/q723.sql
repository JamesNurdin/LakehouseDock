SELECT
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    ws.ws_order_number,
    ws.ws_sales_price,
    ws.ws_net_profit,
    ws.ws_quantity
FROM catalog_returns AS cr
JOIN date_dim AS d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer AS c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_sales AS ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
ORDER BY cr.cr_returned_date_sk DESC
LIMIT 100
