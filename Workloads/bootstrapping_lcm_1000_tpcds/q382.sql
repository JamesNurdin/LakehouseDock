SELECT
    d_sales.d_year,
    d_sales.d_quarter_name,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS total_discount_active,
    MIN(t.t_hour) AS first_hour_of_day,
    MAX(t.t_hour) AS last_hour_of_day
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_channel_tv = 'Y'
GROUP BY
    d_sales.d_year,
    d_sales.d_quarter_name,
    s.s_state,
    s.s_city,
    p.p_promo_name
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
