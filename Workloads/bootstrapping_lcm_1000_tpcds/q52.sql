SELECT
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    c_ret.c_customer_id AS returning_customer_id,
    c_ref.c_customer_id AS refunded_customer_id,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    ws.ws_order_number,
    ws.ws_net_profit,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ship.d_day_name AS ship_day_name,
    ROW_NUMBER() OVER (ORDER BY cr.cr_net_loss DESC) AS net_loss_rank,
    SUM(ws.ws_ext_sales_price) OVER (PARTITION BY c_ret.c_customer_sk) AS total_sales_by_returning_customer,
    SUM(cr.cr_net_loss) OVER (PARTITION BY c_ret.c_customer_sk) AS total_return_loss_by_returning_customer
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE cr.cr_net_loss > 0
ORDER BY net_loss_rank
LIMIT 100
