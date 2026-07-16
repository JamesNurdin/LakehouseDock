SELECT
    s.s_store_name,
    c.c_customer_id,
    d_sale.d_year,
    d_sale.d_month_seq,
    (d_sale.d_year * 100 + d_sale.d_month_seq) AS year_month_key,
    p.p_promo_name,
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END AS promo_channel,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_tax) AS total_tax,
    SUM(p.p_cost) AS total_promo_cost,
    MAX(d_start.d_date) AS promo_start_date,
    MIN(d_end.d_date) AS promo_end_date,
    MAX(d_store_closure.d_date) AS store_closure_date,
    MAX(d_customer_first_shipto.d_date) AS first_shipto_date,
    MAX(d_customer_first_sales.d_date) AS first_sales_date,
    MAX(d_customer_last_review.d_date) AS last_review_date
FROM store_sales ss
JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_store_closure ON s.s_closed_date_sk = d_store_closure.d_date_sk
LEFT JOIN date_dim d_customer_first_shipto ON c.c_first_shipto_date_sk = d_customer_first_shipto.d_date_sk
LEFT JOIN date_dim d_customer_first_sales ON c.c_first_sales_date_sk = d_customer_first_sales.d_date_sk
LEFT JOIN date_dim d_customer_last_review ON c.c_last_review_date = d_customer_last_review.d_date_sk
LEFT JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_sale.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    c.c_customer_id,
    d_sale.d_year,
    d_sale.d_month_seq,
    p.p_promo_name,
    (d_sale.d_year * 100 + d_sale.d_month_seq),
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
