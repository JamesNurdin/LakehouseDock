SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    st.s_store_sk,
    st.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    AVG(wp.wp_image_count) AS avg_image_count,
    MIN(d_wp_create.d_date) AS first_page_creation,
    MAX(d_wp_access.d_date) AS last_page_access,
    MIN(d_cust_first_ship.d_date) AS cust_first_ship_date,
    MIN(d_cust_first_sales.d_date) AS cust_first_sales_date
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer b
  ON cs.cs_bill_customer_sk = b.c_customer_sk
JOIN customer s
  ON cs.cs_ship_customer_sk = s.c_customer_sk
JOIN store st
  ON st.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = b.c_customer_sk
LEFT JOIN date_dim d_wp_create
  ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
LEFT JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN date_dim d_cust_first_ship
  ON b.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
LEFT JOIN date_dim d_cust_first_sales
  ON b.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
WHERE cs.cs_net_paid > 0
GROUP BY
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    st.s_store_sk,
    st.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
