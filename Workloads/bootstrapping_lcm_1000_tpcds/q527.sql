SELECT
    EXTRACT(year FROM d_start.d_date) AS year,
    EXTRACT(month FROM d_start.d_date) AS month,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    COUNT(DISTINCT p.p_promo_id) AS num_promotions,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_web_pages_created,
    COUNT(DISTINCT s.s_store_id) AS num_stores_closed
FROM store s
JOIN date_dim d_start
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_start.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
   AND wp.wp_customer_sk = c.c_customer_sk
GROUP BY
    EXTRACT(year FROM d_start.d_date),
    EXTRACT(month FROM d_start.d_date)
HAVING SUM(p.p_cost) > 1000
ORDER BY year DESC, month DESC
LIMIT 100
