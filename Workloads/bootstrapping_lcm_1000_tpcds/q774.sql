SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    ca.ca_city AS customer_city,
    p.p_promo_id,
    p.p_promo_name,
    d_sold.d_date AS sale_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    d_closed.d_date AS store_closed_date,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    AVG(ss.ss_quantity) AS avg_quantity,
    (SUM(ss.ss_ext_list_price) - SUM(ss.ss_ext_sales_price)) AS total_list_minus_sales,
    CASE
        WHEN SUM(ss.ss_ext_list_price) = 0 THEN NULL
        ELSE (SUM(ss.ss_ext_list_price) - SUM(ss.ss_ext_sales_price)) / SUM(ss.ss_ext_list_price) * 100
    END AS discount_rate_percent
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    ca.ca_city,
    p.p_promo_id,
    p.p_promo_name,
    d_sold.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_closed.d_date
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
