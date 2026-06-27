WITH customer_page_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_current_hdemo_sk,
        COUNT(wp.wp_web_page_sk) AS page_count,
        SUM(wp.wp_char_count) AS total_char_count,
        SUM(wp.wp_link_count) AS total_link_count,
        SUM(wp.wp_image_count) AS total_image_count
    FROM customer c
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    COUNT(DISTINCT cp.c_customer_sk) AS number_of_customers,
    SUM(cp.page_count) AS total_web_pages,
    SUM(cp.total_char_count) / NULLIF(SUM(cp.page_count), 0) AS avg_char_per_page,
    SUM(cp.total_link_count) / NULLIF(SUM(cp.page_count), 0) AS avg_links_per_page,
    SUM(cp.total_image_count) / NULLIF(SUM(cp.page_count), 0) AS avg_images_per_page
FROM customer_page_stats cp
JOIN household_demographics hd
    ON cp.c_current_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
GROUP BY hd.hd_buy_potential, hd.hd_income_band_sk
ORDER BY number_of_customers DESC
LIMIT 20
