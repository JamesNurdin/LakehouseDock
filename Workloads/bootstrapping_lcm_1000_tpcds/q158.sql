SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_state,
    t_ret.t_hour,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    AVG(date_diff('day', d_ret.d_date, d_ship.d_date)) AS avg_days_between_return_and_ship,
    CAST(SUM(cr.cr_return_quantity) AS DOUBLE) / NULLIF(SUM(ws.ws_quantity), 0) AS return_quantity_ratio,
    CAST(SUM(cr.cr_return_amount) AS DOUBLE) / NULLIF(SUM(ws.ws_net_paid_inc_tax), 0) AS return_amount_ratio
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
  ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_ret.d_date_sk
 AND ws.ws_sold_time_sk = t_ret.t_time_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_ret.d_year BETWEEN 1998 AND 2000
  AND t_ret.t_hour BETWEEN 9 AND 17
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    s.s_state,
    t_ret.t_hour
HAVING COUNT(DISTINCT cr.cr_order_number) > 0
ORDER BY total_return_amount DESC
LIMIT 100
