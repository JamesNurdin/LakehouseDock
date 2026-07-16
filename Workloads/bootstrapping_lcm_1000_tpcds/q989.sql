SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    d_store_closed.d_date AS store_closed_date,
    d_ship.d_date AS ship_date,
    bill_addr.ca_city AS bill_city,
    ship_addr.ca_city AS ship_city,
    st.s_store_name,
    st.s_state,
    wp.wp_url,
    d_wp_access.d_year AS wp_access_year,
    (cs.cs_net_paid - cs.cs_wholesale_cost * cs.cs_quantity) AS gross_margin,
    ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS net_paid_rank
FROM store st
JOIN date_dim d_store_closed
    ON st.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address bill_addr
    ON cs.cs_bill_addr_sk = bill_addr.ca_address_sk
JOIN customer_address ship_addr
    ON cs.cs_ship_addr_sk = ship_addr.ca_address_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
ORDER BY net_paid_rank
