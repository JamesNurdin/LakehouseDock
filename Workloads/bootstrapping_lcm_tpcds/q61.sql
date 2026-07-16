SELECT
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    bill_cust.c_customer_id,
    bill_cust.c_first_name,
    bill_cust.c_last_name,
    ship_cust.c_customer_id AS ship_customer_id,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    date_diff('day', d_sold.d_date, d_ship.d_date) AS shipping_delay,
    d_site_open.d_date AS site_open_date,
    d_site_close.d_date AS site_close_date,
    st.s_store_name,
    st.s_city AS store_city,
    st.s_state AS store_state,
    site.web_name,
    site.web_city,
    site.web_country,
    d_cust_first_ship.d_date AS first_ship_to_date,
    d_cust_first_sales.d_date AS first_sales_date
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer bill_cust
    ON ws.ws_bill_customer_sk = bill_cust.c_customer_sk
JOIN customer ship_cust
    ON ws.ws_ship_customer_sk = ship_cust.c_customer_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN date_dim d_site_open
    ON site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON site.web_close_date_sk = d_site_close.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cust_first_ship
    ON bill_cust.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_first_sales
    ON bill_cust.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
ORDER BY ws.ws_net_profit DESC
LIMIT 100
