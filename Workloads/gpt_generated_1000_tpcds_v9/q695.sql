SELECT
    d_date.d_year AS return_year,
    ws.web_name AS website_name,
    r.r_reason_desc AS reason_description,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(CASE WHEN wr.wr_return_ship_cost > 300 THEN wr.wr_return_ship_cost ELSE 0 END) AS high_ship_cost_sum,
    SUM(CASE WHEN wr.wr_net_loss > 500 THEN wr.wr_net_loss ELSE 0 END) AS high_loss_sum
FROM
    web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN date_dim d_date ON wr.wr_returned_date_sk = d_date.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_date.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_date.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY ROLLUP (d_date.d_year, ws.web_name, r.r_reason_desc)
ORDER BY total_net_loss DESC
LIMIT 100
