SELECT
    d_ret.d_year AS year,
    d_ret.d_month_seq AS month_seq,
    sm_ret.sm_type AS return_ship_mode,
    sm_ship.sm_type AS sales_ship_mode,
    s.s_state AS store_state,
    s.s_city AS store_city,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_given,
    SUM(ws.ws_ext_ship_cost) AS total_shipping_cost,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    (SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) AS net_gain_loss
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN ship_mode sm_ret
    ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN ship_mode sm_ship
    ON ws.ws_ship_mode_sk = sm_ship.sm_ship_mode_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    sm_ret.sm_type,
    sm_ship.sm_type,
    s.s_state,
    s.s_city
ORDER BY
    d_ret.d_year,
    d_ret.d_month_seq,
    sm_ret.sm_type,
    sm_ship.sm_type
