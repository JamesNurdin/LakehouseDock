SELECT
    s.s_city,
    s.s_state,
    s.s_manager,
    d_store_closed.d_year AS store_closed_year,
    d_store_closed.d_month_seq AS store_closed_month,
    d_cs_ship.d_year AS catalog_ship_year,
    d_cs_ship.d_month_seq AS catalog_ship_month,
    d_ws_ship.d_year AS web_ship_year,
    d_ws_ship.d_month_seq AS web_ship_month,
    d_wp_access.d_year AS page_access_year,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    AVG(date_diff('day', d_store_closed.d_date, d_cs_ship.d_date)) AS avg_catalog_ship_delay_days,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(ws.ws_net_profit) AS web_net_profit,
    AVG(date_diff('day', d_store_closed.d_date, d_ws_ship.d_date)) AS avg_web_ship_delay_days,
    AVG(date_diff('day', d_wp_creation.d_date, d_store_closed.d_date)) AS avg_page_age_at_sale_days,
    SUM(cs.cs_ext_discount_amt) AS total_catalog_discount,
    SUM(ws.ws_ext_discount_amt) AS total_web_discount,
    AVG(cs.cs_sales_price) AS avg_catalog_sales_price,
    AVG(ws.ws_sales_price) AS avg_web_sales_price
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_city,
    s.s_state,
    s.s_manager,
    d_store_closed.d_year,
    d_store_closed.d_month_seq,
    d_cs_ship.d_year,
    d_cs_ship.d_month_seq,
    d_ws_ship.d_year,
    d_ws_ship.d_month_seq,
    d_wp_access.d_year,
    wp.wp_type
