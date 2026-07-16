WITH promo_store AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_state,
           s.s_city,
           SUM(p.p_cost) AS total_promo_cost,
           COUNT(p.p_promo_sk) AS promo_count
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_city
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_end.d_year AS end_year,
    d_start.d_year AS start_year,
    p.p_promo_name,
    p.p_cost,
    p.p_response_target,
    ps.total_promo_cost,
    ps.promo_count,
    s.s_store_name,
    s.s_state,
    s.s_city,
    wp.wp_url,
    wp.wp_type,
    d_wp_creation.d_day_name AS creation_day,
    d_wp_access.d_day_name AS access_day,
    p.p_discount_active,
    p.p_channel_email,
    p.p_channel_tv,
    p.p_channel_radio,
    (p.p_cost * p.p_response_target) AS estimated_spend,
    RANK() OVER (PARTITION BY s.s_state ORDER BY (p.p_cost * p.p_response_target) DESC) AS spend_rank_state
FROM catalog_page cp
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_end.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN promo_store ps ON ps.s_store_sk = s.s_store_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_end.d_date_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cp.cp_type = 'Holiday'
  AND p.p_discount_active = 'Y'
ORDER BY estimated_spend DESC, cp.cp_catalog_page_number ASC
LIMIT 100
