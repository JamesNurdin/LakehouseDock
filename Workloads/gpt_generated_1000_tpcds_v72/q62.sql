WITH cust_page_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_gmt_offset,
        COUNT(wp.wp_web_page_sk) AS page_count,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(wp.wp_link_count) AS avg_link_count,
        CASE
            WHEN SUM(wp.wp_char_count) > 15000 THEN 'High'
            ELSE 'Low'
        END AS char_volume_category
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_rec_end_date <= DATE '2025-12-31'
      AND wp.wp_char_count > 2000
      AND wp.wp_type = 'Content'
      AND c.c_birth_month IN (1, 5, 9, 12)
      AND ca.ca_gmt_offset >= -8.00
      AND ca.ca_country = 'United States'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_gmt_offset
)
SELECT
    cpa.c_customer_sk,
    cpa.c_first_name,
    cpa.c_last_name,
    cpa.ca_state,
    cpa.page_count,
    cpa.total_char_count,
    cpa.avg_link_count,
    cpa.char_volume_category,
    AVG(cpa.total_char_count) OVER () AS avg_total_char_count,
    ROW_NUMBER() OVER (ORDER BY cpa.total_char_count DESC) AS rn
FROM cust_page_agg cpa
WHERE cpa.total_char_count > (SELECT AVG(total_char_count) FROM cust_page_agg)
ORDER BY cpa.total_char_count DESC
LIMIT 100
