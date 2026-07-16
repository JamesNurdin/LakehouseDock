SELECT
    cp.cp_department,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month_seq,
    s.s_state,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_page_cnt,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS discount_active_cost,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    AVG(CASE WHEN wp.wp_link_count > 0 THEN wp.wp_image_count * 1.0 / wp.wp_link_count END) AS avg_images_per_link,
    COUNT(DISTINCT s.s_store_id) AS store_cnt,
    AVG(s.s_floor_space) AS avg_floor_space,
    SUM(s.s_tax_percentage * s.s_floor_space) AS tax_floor_space_product
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk AND p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk AND wp.wp_access_date_sk = d_end.d_date_sk
GROUP BY cp.cp_department, d_start.d_year, d_start.d_month_seq, s.s_state
ORDER BY total_promo_cost DESC
LIMIT 100
