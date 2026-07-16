SELECT 
    cr_date.d_year AS return_year,
    cr_date.d_month_seq AS return_month,
    s.s_store_id,
    s.s_state,
    web.web_name,
    web.web_state,
    web_open_date.d_date AS site_open_date,
    web_close_date.d_date AS site_close_date,
    date_diff('day', web_open_date.d_date, web_close_date.d_date) AS site_active_days,
    COUNT(*) AS num_transactions,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(ws.ws_quantity) AS total_sales_qty,
    SUM(ws.ws_sales_price) AS total_sales_price,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 0 THEN SUM(cr.cr_return_amount) / SUM(ws.ws_sales_price)
        ELSE NULL
    END AS return_to_sales_ratio,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MAX(ws_ship_date.d_date) AS latest_ship_date
FROM catalog_returns cr
JOIN date_dim cr_date ON cr.cr_returned_date_sk = cr_date.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = cr_date.d_date_sk
JOIN date_dim ws_ship_date ON ws.ws_ship_date_sk = ws_ship_date.d_date_sk
JOIN store s ON s.s_closed_date_sk = cr_date.d_date_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim web_open_date ON web.web_open_date_sk = web_open_date.d_date_sk
JOIN date_dim web_close_date ON web.web_close_date_sk = web_close_date.d_date_sk
WHERE cr.cr_return_quantity > 0
GROUP BY 
    cr_date.d_year,
    cr_date.d_month_seq,
    s.s_store_id,
    s.s_state,
    web.web_name,
    web.web_state,
    web_open_date.d_date,
    web_close_date.d_date
ORDER BY total_return_amount DESC
LIMIT 100
