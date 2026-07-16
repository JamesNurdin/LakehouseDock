SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    ca_bill.ca_city AS bill_city,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_city AS ship_city,
    ca_ship.ca_state AS ship_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS num_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS discount_rate,
    AVG(ws.ws_quantity) AS avg_quantity
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_promo_start.d_date,
    d_promo_end.d_date,
    ca_bill.ca_city,
    ca_bill.ca_state,
    ca_ship.ca_city,
    ca_ship.ca_state
ORDER BY total_sales DESC
LIMIT 100
