SELECT
    d_ret.d_year AS year,
    d_ret.d_month_seq AS month_seq,
    s.s_city AS store_city,
    s.s_state AS store_state,
    COUNT(DISTINCT cr.cr_order_number) AS total_returns,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales_net_paid,
    SUM(ws.ws_net_profit) AS total_sales_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    CASE
        WHEN SUM(ws.ws_net_profit) = 0 THEN NULL
        ELSE SUM(cr.cr_net_loss) / SUM(ws.ws_net_profit)
    END AS loss_to_profit_ratio,
    MIN(t_ret.t_hour) AS earliest_return_hour,
    MAX(t_ws.t_hour) AS latest_sales_hour,
    AVG(date_diff('day', d_ship.d_date, d_ret.d_date)) AS avg_ship_to_return_days
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY d_ret.d_year, d_ret.d_month_seq, s.s_city, s.s_state
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY d_ret.d_year, d_ret.d_month_seq, s.s_city
LIMIT 100
