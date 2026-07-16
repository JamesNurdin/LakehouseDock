SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    w.w_warehouse_name,
    ws_site.web_name AS site_name,
    ws_site.web_city AS site_city,
    ws_site.web_state AS site_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_site_open
    ON ws_site.web_open_date_sk = d_site_open.d_date_sk
LEFT JOIN date_dim d_site_close
    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year >= 2020
  AND d_site_open.d_date <= d_sold.d_date
  AND (d_site_close.d_date IS NULL OR d_site_close.d_date >= d_ship.d_date)
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    ws_site.web_name,
    ws_site.web_city,
    ws_site.web_state
ORDER BY total_net_profit DESC
LIMIT 100
