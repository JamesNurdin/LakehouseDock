WITH wp_agg AS (
    SELECT
        wp_customer_sk,
        SUM(wp_char_count) AS total_char,
        COUNT(*) AS page_cnt,
        AVG(wp_link_count) AS avg_links,
        CASE WHEN SUM(wp_image_count) > 0 THEN 'HAS_IMG' ELSE 'NO_IMG' END AS image_flag
    FROM web_page
    WHERE wp_autogen_flag = 'Y'
    GROUP BY wp_customer_sk
),
joined AS (
    SELECT
        cc.cc_division,
        cc.cc_division_name,
        ca.ca_state,
        d_closed.d_year AS closed_year,
        c.c_birth_year,
        wp.total_char,
        wp.page_cnt,
        wp.avg_links,
        wp.image_flag
    FROM call_center cc
    JOIN date_dim d_closed
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN customer c
        ON c.c_first_sales_date_sk = d_closed.d_date_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN wp_agg wp
        ON c.c_customer_sk = wp.wp_customer_sk
    WHERE cc.cc_sq_ft > 1000000
      AND cc.cc_state = 'CA'
      AND c.c_birth_year BETWEEN 1960 AND 2000
      AND d_closed.d_year = 2002
)
SELECT
    cc_division,
    cc_division_name,
    ca_state,
    COUNT(*) AS num_customers,
    SUM(total_char) AS sum_total_char,
    AVG(page_cnt) AS avg_page_cnt,
    MAX(CASE WHEN image_flag = 'HAS_IMG' THEN total_char ELSE 0 END) AS max_char_with_images
FROM joined
GROUP BY cc_division, cc_division_name, ca_state
HAVING COUNT(*) >= 5
ORDER BY sum_total_char DESC
LIMIT 100
