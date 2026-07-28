WITH
    agg_returns AS (
        SELECT
            wr_order_number,
            SUM(wr_return_amt_inc_tax)   AS total_return_amt_inc_tax,
            SUM(wr_net_loss)            AS total_return_net_loss
        FROM web_returns
        GROUP BY wr_order_number
    ),
    return_dates AS (
        SELECT
            wr_order_number,
            MIN(wr_returned_date_sk) AS return_date_sk,
            MIN(wr_returned_time_sk) AS return_time_sk
        FROM web_returns
        GROUP BY wr_order_number
    ),
    distinct_promos AS (
        SELECT DISTINCT
            p.p_promo_sk,
            p.p_promo_name,
            p.p_start_date_sk
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        WHERE d_start.d_year = 2001
    )
SELECT
    d_sold.d_year                         AS sale_year,
    d_sold.d_month_seq                    AS sale_month,
    sm.sm_type                             AS ship_mode_type,
    w.w_warehouse_name                     AS warehouse_name,
    cc.cc_state                            AS call_center_state,
    dp.p_promo_name                        AS promotion_name,
    SUM(ws.ws_ext_sales_price)             AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt)           AS total_discount_amount,
    SUM(ws.ws_net_profit)                 AS total_net_profit,
    COALESCE(SUM(ar.total_return_amt_inc_tax), 0) AS total_return_amount,
    COALESCE(SUM(ar.total_return_net_loss), 0)   AS total_return_loss
FROM web_sales ws
JOIN date_dim d_sold      ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship      ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN distinct_promos dp   ON ws.ws_promo_sk = dp.p_promo_sk
JOIN time_dim t_sold      ON ws.ws_sold_time_sk = t_sold.t_time_sk
LEFT JOIN agg_returns ar   ON ws.ws_order_number = ar.wr_order_number
LEFT JOIN return_dates rd   ON ws.ws_order_number = rd.wr_order_number
LEFT JOIN date_dim d_return ON rd.return_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return ON rd.return_time_sk = t_return.t_time_sk
LEFT JOIN call_center cc   ON cc.cc_closed_date_sk = d_ship.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    w.w_warehouse_name,
    cc.cc_state,
    dp.p_promo_name
ORDER BY total_sales_amount DESC
LIMIT 100
