WITH wp_summary AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_count,
        SUM(wp_char_count) AS total_char,
        AVG(wp_image_count) AS avg_image,
        MAX(wp_char_count) AS max_char,
        MIN(wp_char_count) AS min_char
    FROM web_page
    WHERE wp_char_count BETWEEN 1200 AND 1600
      AND wp_image_count >= 4
      AND wp_type IN ('article', 'product')
    GROUP BY wp_customer_sk
)
SELECT
    COALESCE(c.c_customer_id, 'ALL_CUSTOMERS') AS customer_id,
    COALESCE(ca.ca_state, 'ALL_STATES') AS state,
    SUM(ws.page_count) AS total_pages,
    SUM(ws.total_char) AS total_characters,
    AVG(ws.avg_image) AS avg_images_per_page,
    COUNT(DISTINCT ws.wp_customer_sk) AS distinct_customers,
    (SELECT AVG(wp_char_count) FROM web_page) AS overall_avg_char
FROM wp_summary ws
JOIN customer c
    ON ws.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_year BETWEEN 1935 AND 1990
  AND ca.ca_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'article'
    )
GROUP BY GROUPING SETS (
    (c.c_customer_id, ca.ca_state),
    (c.c_customer_id),
    (ca.ca_state),
    ()
)
HAVING SUM(ws.page_count) >= 5
ORDER BY
    CASE WHEN GROUPING(c.c_customer_id) = 0 THEN 0 ELSE 1 END,
    total_pages DESC
LIMIT 100
