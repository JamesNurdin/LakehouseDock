WITH web_agg AS (
    SELECT
        wp_customer_sk,
        SUM(wp_char_count) AS total_char_count,
        SUM(wp_image_count) AS total_image_count,
        COUNT(*) AS page_count,
        MAX(wp_rec_end_date) AS latest_rec_end_date
    FROM web_page
    WHERE wp_type = 'article'
    GROUP BY wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_email_address,
    ca.ca_city,
    ca.ca_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wa.total_char_count,
    wa.total_image_count,
    wa.page_count,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY wa.total_char_count DESC) AS income_band_char_rank
FROM web_agg wa
JOIN customer c
    ON wa.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE c.c_email_address LIKE '%@o.org'
  AND ca.ca_location_type = 'single family'
  AND ib.ib_lower_bound >= 30000
  AND wa.latest_rec_end_date <= DATE '2001-12-31'
ORDER BY income_band_char_rank, wa.total_char_count DESC
LIMIT 100
