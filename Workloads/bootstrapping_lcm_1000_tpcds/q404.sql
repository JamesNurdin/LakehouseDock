SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    d_closed.d_date AS store_closed_date,
    DATE_DIFF('day', d_promo_start.d_date, d_sold.d_date) AS days_since_promo_start,
    DATE_DIFF('day', d_sold.d_date, d_promo_end.d_date) AS days_until_promo_end,
    DATE_DIFF('day', d_cust_first_sales.d_date, d_sold.d_date) AS days_since_customer_first_sale,
    DATE_DIFF('day', d_cust_first_ship.d_date, d_sold.d_date) AS days_since_customer_first_ship
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_first_ship
    ON c.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND d_sold.d_date >= d_promo_start.d_date
  AND d_sold.d_date <= d_promo_end.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_closed.d_date,
    d_cust_first_sales.d_date,
    d_cust_first_ship.d_date
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
