WITH customer_page_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        COUNT(wp.wp_web_page_sk) AS page_count,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(wp.wp_link_count) AS avg_link_count,
        MAX(wp.wp_image_count) AS max_image_count,
        MIN(wp.wp_rec_start_date) AS first_page_date,
        MAX(wp.wp_rec_end_date) AS last_page_date
    FROM
        customer c
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        wp.wp_rec_start_date >= DATE '2020-01-01'
        AND wp.wp_rec_end_date <= DATE '2023-12-31'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        c.c_birth_year,
        c.c_preferred_cust_flag
),
ranked_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_birth_country,
        c_birth_year,
        c_preferred_cust_flag,
        page_count,
        total_char_count,
        avg_link_count,
        max_image_count,
        first_page_date,
        last_page_date,
        ROW_NUMBER() OVER (PARTITION BY c_birth_country ORDER BY page_count DESC) AS country_page_rank
    FROM
        customer_page_stats
)
SELECT
    c_birth_country,
    c_birth_year,
    c_preferred_cust_flag,
    COUNT(*) AS num_customers,
    SUM(page_count) AS total_pages,
    AVG(total_char_count) AS avg_chars_per_customer,
    AVG(avg_link_count) AS avg_links_per_page,
    MAX(max_image_count) AS max_images_on_page,
    MAX(country_page_rank) AS max_page_rank_in_country
FROM
    ranked_customers
WHERE
    country_page_rank <= 5
GROUP BY
    c_birth_country,
    c_birth_year,
    c_preferred_cust_flag
ORDER BY
    total_pages DESC
LIMIT 20
