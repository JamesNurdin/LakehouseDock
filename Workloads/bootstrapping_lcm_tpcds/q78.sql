SELECT
    d_sales.d_year AS sales_year,
    s.s_state AS store_state,
    w.web_state AS website_state,
    CASE WHEN s.s_floor_space > 20000 THEN 'Large' ELSE 'Small' END AS store_size_category,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    COUNT(DISTINCT p.p_promo_sk) AS promo_count,
    COUNT(DISTINCT w.web_site_id) AS website_count,
    MIN(d_store_closed.d_year) AS store_closed_year,
    MAX(d_web_open.d_year) AS website_open_year
FROM customer c
JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_sales.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN date_dim d_store_closed
JOIN store s ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN web_site w
JOIN date_dim d_web_open ON w.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON w.web_close_date_sk = d_web_close.d_date_sk
GROUP BY
    d_sales.d_year,
    s.s_state,
    w.web_state,
    CASE WHEN s.s_floor_space > 20000 THEN 'Large' ELSE 'Small' END
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY sales_year DESC, total_promo_cost DESC
LIMIT 100
