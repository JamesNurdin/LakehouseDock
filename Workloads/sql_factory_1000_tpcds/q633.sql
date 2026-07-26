SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_char_count,
    wp.wp_link_count,
    wp.wp_image_count,
    cd.d_date AS creation_date,
    ad.d_date AS access_date,
    date_diff('day', cd.d_date, ad.d_date) AS days_active,
    CASE
        WHEN date_diff('day', cd.d_date, ad.d_date) > 365 THEN 'Long-lived'
        ELSE 'Short-lived'
    END AS life_category,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY wp.wp_link_count DESC) AS link_rank,
    SUM(wp.wp_char_count) OVER (PARTITION BY wp.wp_type ORDER BY wp.wp_char_count ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_char_count
FROM web_page wp
JOIN date_dim cd ON wp.wp_creation_date_sk = cd.d_date_sk
JOIN date_dim ad ON wp.wp_access_date_sk = ad.d_date_sk
WHERE wp.wp_autogen_flag = 'N'
