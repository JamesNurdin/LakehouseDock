SELECT
    p.p_promo_name,
    s.s_store_name,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_bill_customers,
    COUNT(DISTINCT c_ship.c_customer_sk) AS distinct_ship_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date,
    MIN(d_cust_first_ship.d_date) AS first_shipto_date,
    MIN(d_cust_first_sales.d_date) AS first_sales_date,
    MIN(d_cust_last_review.d_date) AS last_review_date,
    COUNT(DISTINCT c_ship.c_birth_country) AS distinct_ship_countries
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_cust_first_ship ON c_bill.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_first_sales ON c_bill.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_last_review ON c_bill.c_last_review_date = d_cust_last_review.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
  AND d_sold.d_date <= d_store_closed.d_date
  AND c_bill.c_birth_month = 6
  AND s.s_state = 'CA'
GROUP BY
    p.p_promo_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY
    total_sales_amount DESC
LIMIT 100
