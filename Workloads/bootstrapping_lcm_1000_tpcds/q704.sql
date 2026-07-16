SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url,
    wsit.web_name,
    wsit.web_market_manager,
    SUM(ws.ws_quantity * ws.ws_sales_price) AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_order_count,
    AVG(ws.ws_sales_price) AS average_sales_price
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_open ON wsit.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON wsit.web_close_date_sk = d_close.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND ws.ws_quantity > 0
  AND ws.ws_sales_price > 0
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url,
    wsit.web_name,
    wsit.web_market_manager
ORDER BY total_sales_amount DESC
LIMIT 100
