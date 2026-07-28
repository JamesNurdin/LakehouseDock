WITH joined_data AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        td.t_shift,
        td.t_hour,
        c_bill.c_customer_sk AS billing_customer_sk,
        c_bill.c_birth_year AS billing_birth_year,
        c_ship.c_customer_sk AS shipping_customer_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_account_credit,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_sales ws
    INNER JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    INNER JOIN time_dim td_ret
        ON wr.wr_returned_time_sk = td_ret.t_time_sk
    INNER JOIN customer c_refund
        ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    WHERE td.t_shift = 'first'
      AND c_bill.c_birth_year >= 1970
      AND w.w_state = 'CA'
      AND wr.wr_account_credit > 100
)
SELECT
    w_warehouse_name,
    t_shift,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM joined_data
GROUP BY ROLLUP (w_warehouse_name, t_shift)
HAVING SUM(ws_ext_sales_price) > 1000
ORDER BY profit_rank
LIMIT 100
