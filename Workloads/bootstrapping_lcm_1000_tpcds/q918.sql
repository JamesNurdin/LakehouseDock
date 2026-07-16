SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_week_seq,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    SUM(cs.cs_coupon_amt) AS total_coupon,
    MAX(wp.wp_url) FILTER (WHERE wp.wp_url IS NOT NULL) AS sample_url,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
   AND wp.wp_access_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = ca_bill.ca_state
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_week_seq,
    d_ship.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca_bill.ca_state,
    ca_ship.ca_state
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
