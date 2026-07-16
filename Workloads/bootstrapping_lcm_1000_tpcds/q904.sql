SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    CASE WHEN ws.ws_quantity > 10 THEN 'large' ELSE 'small' END AS quantity_category,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    MAX(ws.ws_net_profit) AS max_profit,
    SUM(ws.ws_net_paid) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    AVG(date_diff('day', d_wp_creation.d_date, d_sold.d_date)) AS avg_creation_to_sale_days,
    MAX(date_diff('day', d_wp_access.d_date, d_sold.d_date)) AS max_access_to_sale_days
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca_bill.ca_state,
    ca_ship.ca_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    CASE WHEN ws.ws_quantity > 10 THEN 'large' ELSE 'small' END
ORDER BY total_sales DESC
LIMIT 100
