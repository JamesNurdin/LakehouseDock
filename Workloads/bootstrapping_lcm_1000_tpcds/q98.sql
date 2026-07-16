SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    CASE WHEN d_sales.d_month_seq <= 6 THEN 'FirstHalf' ELSE 'SecondHalf' END AS half_year,
    wp.wp_type,
    wp.wp_url,
    c_page.c_birth_country,
    d_cust_first_sales.d_year AS cust_first_sales_year,
    d_cust_first_ship.d_year AS cust_first_ship_year,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT c_bill.c_customer_sk) AS num_billing_customers,
    COUNT(DISTINCT c_ship.c_customer_sk) AS num_shipping_customers,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost,
    ROUND(SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0), 4) AS profit_margin,
    ROUND(SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0), 4) AS discount_rate,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(d_sales.d_date) AS last_sale_date
FROM web_sales ws
JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c_page ON wp.wp_customer_sk = c_page.c_customer_sk
JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN date_dim d_cust_first_ship ON c_page.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_first_sales ON c_page.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
WHERE wp.wp_type = 'product'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    CASE WHEN d_sales.d_month_seq <= 6 THEN 'FirstHalf' ELSE 'SecondHalf' END,
    wp.wp_type,
    wp.wp_url,
    c_page.c_birth_country,
    d_cust_first_sales.d_year,
    d_cust_first_ship.d_year
HAVING SUM(ws.ws_ext_sales_price) > 1000
