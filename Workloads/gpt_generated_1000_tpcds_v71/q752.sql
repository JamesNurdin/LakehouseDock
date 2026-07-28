WITH site_page_stats AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d_open.d_year AS open_year,
        COUNT(DISTINCT wc.c_customer_sk) AS unique_customers,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(wp.wp_char_count) AS avg_char_count,
        SUM(wp.wp_link_count) AS total_link_count
    FROM web_site ws
    JOIN date_dim d_open
        ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_open.d_date_sk
    JOIN customer wc
        ON wp.wp_customer_sk = wc.c_customer_sk
    JOIN customer_address ca
        ON wc.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.web_country = 'United States'
      AND ca.ca_state = 'CA'
      AND wp.wp_type = 'Content'
      AND d_open.d_year BETWEEN 2000 AND 2002
      AND wp.wp_char_count > 1000
    GROUP BY ws.web_site_id, ws.web_name, d_open.d_year
)
SELECT
    open_year,
    AVG(unique_customers) AS avg_unique_customers,
    SUM(total_char_count) AS sum_char_count,
    AVG(avg_char_count) AS avg_page_char_count
FROM site_page_stats
WHERE total_link_count > 10
GROUP BY open_year
HAVING SUM(total_char_count) > 50000
ORDER BY sum_char_count DESC
LIMIT 100
