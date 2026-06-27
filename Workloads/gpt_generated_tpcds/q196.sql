WITH preferred_customer_pages AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        w.wp_type,
        w.wp_char_count,
        w.wp_link_count,
        w.wp_image_count,
        w.wp_max_ad_count
    FROM
        customer c
    JOIN
        web_page w
        ON w.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
)
SELECT
    c_birth_year,
    c_birth_month,
    wp_type,
    COUNT(*) AS page_visits,
    AVG(wp_char_count) AS avg_char_count,
    AVG(wp_link_count) AS avg_link_count,
    AVG(wp_image_count) AS avg_image_count,
    AVG(CAST(wp_image_count AS double) * 1000.0 / wp_char_count) AS avg_images_per_1000_chars,
    SUM(wp_max_ad_count) AS total_max_ad_count
FROM
    preferred_customer_pages
GROUP BY
    c_birth_year,
    c_birth_month,
    wp_type
ORDER BY
    page_visits DESC
LIMIT 20
