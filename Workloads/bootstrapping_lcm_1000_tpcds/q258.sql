SELECT
    d_ret.d_year AS return_year,
    d_ret.d_current_month AS return_month,
    s.s_state AS store_state,
    ws.web_state AS website_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    CASE
        WHEN cr.cr_net_loss > 100 THEN 'High'
        WHEN cr.cr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END AS net_loss_category,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee + cr.cr_return_tax + cr.cr_return_ship_cost) AS total_fees,
    date_diff('day', d_ret.d_date, d_close.d_date) AS website_lifespan_days
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_current_month,
    s.s_state,
    ws.web_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    CASE
        WHEN cr.cr_net_loss > 100 THEN 'High'
        WHEN cr.cr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END,
    date_diff('day', d_ret.d_date, d_close.d_date)
