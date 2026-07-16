SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
    SUM(wp.wp_link_count) AS total_links,
    AVG(wp.wp_image_count) AS avg_images_per_page,
    SUM(wp.wp_char_count) AS total_characters,
    ROUND(AVG(wp.wp_char_count * 1.0 / NULLIF(wp.wp_link_count, 0)), 2) AS avg_chars_per_link,
    RANK() OVER (ORDER BY SUM(wp.wp_link_count) DESC) AS link_rank
FROM web_page wp
JOIN customer c
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE wp.wp_type = 'article'
  AND wp.wp_access_date_sk BETWEEN 20200101 AND 20201231
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING COUNT(DISTINCT wp.wp_web_page_sk) >= 10
ORDER BY total_links DESC
LIMIT 50
