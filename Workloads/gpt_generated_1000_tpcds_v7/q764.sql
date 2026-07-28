WITH sales_returns AS (
    SELECT
        p.p_promo_name,
        sm.sm_type,
        td_sold.t_am_pm,
        ws.ws_order_number,
        ws.ws_net_profit,
        wr.wr_return_amt
    FROM web_sales ws
    JOIN time_dim td_sold
        ON ws.ws_sold_time_sk = td_sold.t_time_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN time_dim td_ret
        ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN customer c_refund
        ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN web_sales ws_item
        ON wr.wr_item_sk = ws_item.ws_item_sk
    WHERE p.p_start_date_sk BETWEEN 2450300 AND 2450400
      AND td_sold.t_minute IN (0, 14, 15)
)
SELECT
    p_promo_name,
    sm_type,
    t_am_pm,
    total_net_profit,
    total_return_amount,
    order_cnt,
    RANK() OVER (PARTITION BY sm_type ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        p_promo_name,
        sm_type,
        t_am_pm,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM sales_returns
    GROUP BY p_promo_name, sm_type, t_am_pm
) agg
ORDER BY total_net_profit DESC
LIMIT 100
