WITH demo_page_stats AS (
    SELECT
        cd.cd_education_status AS education_status,
        cd.cd_gender AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        COUNT(wp.wp_web_page_sk) AS total_pages,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_link_count) AS avg_links_per_page,
        SUM(wp.wp_image_count) AS total_images,
        approx_percentile(wp.wp_char_count, 0.9) AS p90_char_count,
        MAX(wp.wp_rec_start_date) AS latest_page_start_date
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_country IN ('CHILE', 'MEXICO')
      AND wp.wp_rec_start_date >= DATE '2020-01-01'
      AND wp.wp_type = 'article'
    GROUP BY cd.cd_education_status, cd.cd_gender
    HAVING COUNT(wp.wp_web_page_sk) >= 10
)
SELECT
    education_status,
    gender,
    num_customers,
    total_pages,
    total_links,
    avg_links_per_page,
    total_images,
    p90_char_count,
    latest_page_start_date,
    ROW_NUMBER() OVER (ORDER BY total_links DESC) AS rank_by_total_links
FROM demo_page_stats
ORDER BY total_links DESC
LIMIT 100
