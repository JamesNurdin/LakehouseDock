SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month,
    s.s_store_id,
    s.s_store_name,
    d_closed.d_year AS store_closed_year,
    SUM(ss.ss_net_paid) AS store_total_net_paid,
    SUM(ss.ss_net_profit) AS store_total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS store_avg_discount,
    SUM(ss.ss_quantity) AS store_total_quantity,
    d_ws_sold.d_year AS web_sales_year,
    d_ws_sold.d_month_seq AS web_sales_month,
    d_ws_ship.d_year AS web_ship_year,
    wp.wp_web_page_id,
    wp.wp_url,
    d_creation.d_year AS page_creation_year,
    d_access.d_year AS page_access_year,
    SUM(ws.ws_net_paid) AS web_total_net_paid,
    SUM(ws.ws_net_profit) AS web_total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS web_avg_discount,
    SUM(ws.ws_quantity) AS web_total_quantity
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    d_closed.d_year,
    d_ws_sold.d_year,
    d_ws_sold.d_month_seq,
    d_ws_ship.d_year,
    wp.wp_web_page_id,
    wp.wp_url,
    d_creation.d_year,
    d_access.d_year
ORDER BY store_total_net_paid DESC
LIMIT 100
