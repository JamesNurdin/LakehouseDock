SELECT
    d_start.d_year,
    d_start.d_quarter_name,
    d_start.d_day_name AS promo_start_day,
    d_end.d_day_name AS promo_end_day,
    d_access.d_day_name AS page_access_day,
    s.s_store_name,
    s.s_state,
    s.s_geography_class,
    s.s_tax_percentage,
    p.p_promo_name,
    p.p_cost,
    p.p_response_target,
    (p.p_cost * p.p_response_target) AS projected_spend,
    p.p_discount_active,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_url,
    CASE WHEN wp.wp_image_count > 0 THEN 'HasImages' ELSE 'NoImages' END AS image_flag,
    (wp.wp_image_count / NULLIF(p.p_response_target, 0)) AS images_per_target,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY (p.p_cost * p.p_response_target) DESC) AS state_spend_rank
FROM promotion p
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE
    p.p_discount_active = 'Y'
    AND s.s_state IN ('CA', 'NY', 'TX')
    AND wp.wp_type = 'product'
ORDER BY
    projected_spend DESC,
    d_start.d_year DESC
LIMIT 100
