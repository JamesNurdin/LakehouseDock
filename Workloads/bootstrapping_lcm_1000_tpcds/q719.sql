SELECT
    d_start.d_year AS promo_start_year,
    d_end.d_year AS promo_end_year,
    p.p_promo_id,
    p.p_promo_name,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    ws.web_site_id,
    ws.web_name,
    COUNT(DISTINCT wp.wp_web_page_id) AS page_count,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    d_close.d_year AS site_close_year
FROM promotion p
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
GROUP BY
    d_start.d_year,
    d_end.d_year,
    p.p_promo_id,
    p.p_promo_name,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    ws.web_site_id,
    ws.web_name,
    d_close.d_year
ORDER BY d_start.d_year, p.p_promo_id
