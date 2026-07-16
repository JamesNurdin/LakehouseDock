SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_store_name,
    s.s_city,
    wp.wp_url,
    wp.wp_type,
    d_cre.d_current_day AS page_creation_day,
    d_acc.d_current_day AS page_access_day,
    COALESCE(d_ship.d_current_day, 'N/A') AS ship_day,
    COALESCE(d_closed.d_current_day, 'N/A') AS store_closed_day,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_orders,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    (SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) AS net_profit_after_returns
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_cre
    ON wp.wp_creation_date_sk = d_cre.d_date_sk
JOIN date_dim d_acc
    ON wp.wp_access_date_sk = d_acc.d_date_sk
LEFT JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
WHERE ws.ws_quantity > 0
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_name,
    s.s_city,
    wp.wp_url,
    wp.wp_type,
    d_cre.d_current_day,
    d_acc.d_current_day,
    d_ship.d_current_day,
    d_closed.d_current_day
ORDER BY net_profit_after_returns DESC
LIMIT 100
