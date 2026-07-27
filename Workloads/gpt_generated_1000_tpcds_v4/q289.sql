WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        SUM(wr.wr_fee) AS total_return_fee,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
    GROUP BY wr.wr_order_number
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    t_sold.t_meal_time,
    COUNT(DISTINCT ws.ws_order_number) AS orders_sold,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COALESCE(r.total_return_amt, 0) AS total_returns,
    CASE
        WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_category
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_site_open ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close ON wsite.web_close_date_sk = d_site_close.d_date_sk
LEFT JOIN returns_agg r ON ws.ws_order_number = r.wr_order_number
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    t_sold.t_meal_time,
    COALESCE(r.total_return_amt, 0)
ORDER BY d_sold.d_year, d_sold.d_month_seq
