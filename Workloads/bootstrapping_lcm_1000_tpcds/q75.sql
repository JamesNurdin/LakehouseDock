SELECT
    (d_sold.d_year * 10 + d_sold.d_quarter_seq) AS year_quarter_key,
    CASE WHEN d_ship.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS ship_half,
    w.w_state AS warehouse_state,
    s.s_division_name AS store_division,
    wp.wp_type AS page_type,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_quantity) AS avg_quantity,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(ws.ws_net_paid) / SUM(ws.ws_ext_sales_price) ELSE NULL END AS net_to_sales_ratio
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year >= 1998
GROUP BY
    (d_sold.d_year * 10 + d_sold.d_quarter_seq),
    CASE WHEN d_ship.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    w.w_state,
    s.s_division_name,
    wp.wp_type
HAVING SUM(ws.ws_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
