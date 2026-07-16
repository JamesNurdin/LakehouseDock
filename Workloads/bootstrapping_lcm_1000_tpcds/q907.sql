SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_closed.d_current_month AS store_closed_month,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) + 1 AS promo_duration_days,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(wp.wp_char_count) AS avg_char_count
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE p.p_discount_active = 'Y'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_closed.d_current_month,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_date,
    d_promo_end.d_date
ORDER BY total_sales DESC
LIMIT 100
