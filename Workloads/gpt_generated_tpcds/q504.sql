SELECT
    d_creation.d_year AS creation_year,
    d_access.d_year AS access_year,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
    AVG(wp.wp_char_count) AS avg_char_count,
    SUM(wp.wp_link_count) AS total_links,
    SUM(wp.wp_image_count) AS total_images
FROM web_page wp
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_creation.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY d_creation.d_year, d_access.d_year
ORDER BY d_creation.d_year, d_access.d_year
