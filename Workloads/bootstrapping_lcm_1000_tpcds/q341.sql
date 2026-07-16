SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    (d.d_week_seq % 2) AS week_parity,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(p.p_cost) FILTER (WHERE p.p_cost IS NOT NULL) AS avg_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_sales_price * 0.1 ELSE 0 END) AS discount_sales_estimate,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    MAX(date_diff('day', d_start.d_date, d_end.d_date)) AS promo_length_days
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    (d.d_week_seq % 2)
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
