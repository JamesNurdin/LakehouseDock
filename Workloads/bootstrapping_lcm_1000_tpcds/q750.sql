SELECT
    cp.cp_type,
    cp.cp_department,
    wp.wp_type AS web_page_type,
    s.s_state,
    s.s_city,
    EXTRACT(year FROM sold_d.d_date)   AS sold_year,
    EXTRACT(month FROM sold_d.d_date)  AS sold_month,
    SUM(ws.ws_ext_sales_price)          AS total_sales,
    SUM(ws.ws_net_profit)               AS total_profit,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_quantity)                AS avg_quantity,
    SUM(ws.ws_ext_discount_amt)        AS total_discount,
    SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_qty_sales,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High'
        ELSE 'Low'
    END                                 AS sales_category
FROM web_sales ws
JOIN date_dim sold_d
    ON ws.ws_sold_date_sk = sold_d.d_date_sk
JOIN date_dim ship_d
    ON ws.ws_ship_date_sk = ship_d.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim wp_creation_d
    ON wp.wp_creation_date_sk = wp_creation_d.d_date_sk
JOIN date_dim wp_access_d
    ON wp.wp_access_date_sk = wp_access_d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = wp_creation_d.d_date_sk
JOIN date_dim cp_end_d
    ON cp.cp_end_date_sk = cp_end_d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ship_d.d_date_sk
WHERE sold_d.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    cp.cp_type,
    cp.cp_department,
    wp.wp_type,
    s.s_state,
    s.s_city,
    EXTRACT(year FROM sold_d.d_date),
    EXTRACT(month FROM sold_d.d_date)
