WITH wp_agg AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_cnt,
        SUM(wp_char_count) AS total_chars,
        MAX(wp_rec_end_date) AS latest_end_date
    FROM web_page
    WHERE wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND wp_url LIKE 'http://www.%'
      AND wp_autogen_flag = 'N'
      AND wp_type IN ('home', 'landing')
      AND wp_char_count > 0
      AND wp_link_count >= 1
    GROUP BY wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    agg.total_chars,
    agg.page_cnt,
    agg.latest_end_date,
    CASE
        WHEN agg.total_chars >= 200000 THEN 'High'
        WHEN agg.total_chars >= 100000 THEN 'Medium'
        ELSE 'Low'
    END AS activity_level,
    RANK() OVER (ORDER BY agg.total_chars DESC) AS char_rank
FROM wp_agg agg
JOIN customer c
    ON agg.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990                                   -- predicate 1
  AND c.c_preferred_cust_flag = 'Y'                                          -- predicate 2
  AND ca.ca_gmt_offset BETWEEN -9 AND -5                                    -- predicate 3
  AND ca.ca_state = 'CA'                                                     -- predicate 4
  AND ca.ca_suite_number LIKE 'Suite %'                                      -- predicate 5
  AND c.c_current_cdemo_sk IS NOT NULL                                      -- predicate 6
  AND c.c_customer_sk NOT IN (
        SELECT wp_customer_sk
        FROM web_page
        WHERE wp_type = 'advertisement'
          AND wp_char_count < 100
    )
ORDER BY agg.total_chars DESC, c.c_customer_id
LIMIT 100
