WITH per_customer AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_birth_month AS birth_month,
        c.c_preferred_cust_flag AS preferred_flag,
        wp.wp_type AS type,
        SUM(wp.wp_image_count) AS total_images,
        SUM(wp.wp_link_count) AS total_links,
        COUNT(*) AS page_cnt
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month IN (1, 4, 6, 7, 8)
      AND c.c_birth_year BETWEEN 1950 AND 2000
      AND wp.wp_type NOT IN ('protected')
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_image_count >= 3
    GROUP BY c.c_customer_sk, c.c_birth_month, c.c_preferred_cust_flag, wp.wp_type
)
SELECT
    birth_month,
    type,
    SUM(total_images) AS sum_images,
    AVG(total_links) AS avg_links,
    COUNT(DISTINCT customer_sk) AS distinct_customers,
    GROUPING(birth_month) AS g_birth_month,
    GROUPING(type) AS g_type
FROM per_customer
GROUP BY ROLLUP (birth_month, type)
HAVING SUM(total_images) > 10
ORDER BY sum_images DESC
LIMIT 100
