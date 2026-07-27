WITH page_stats AS (
    SELECT
        wp.wp_customer_sk,
        REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        SUM(wp.wp_char_count) AS total_char_count,
        MAX(wp.wp_char_count) AS max_char_count
    FROM web_page wp
    WHERE wp.wp_type LIKE 'article%'
      AND REGEXP_LIKE(wp.wp_url, '^https?://.*sports.*$')
    GROUP BY wp.wp_customer_sk, REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ps.distinct_pages,
    ps.total_char_count,
    ps.max_char_count,
    ps.domain,
    (
        SELECT COUNT(*)
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_char_count > ps.max_char_count
    ) AS higher_char_pages
FROM customer c
JOIN page_stats ps
    ON ps.wp_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
ORDER BY ps.total_char_count DESC
LIMIT 100
