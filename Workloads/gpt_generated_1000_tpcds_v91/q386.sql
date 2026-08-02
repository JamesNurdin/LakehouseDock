WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        c.c_last_review_date,
        ca.ca_city,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        cd.cd_gender,
        cd.cd_education_status,
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_image_count,
        c.c_current_hdemo_sk
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1960 AND 1975
      AND ca.ca_location_type = 'apartment'
      AND ca.ca_state = 'CA'
      AND ca.ca_gmt_offset = -5.00
      AND cd.cd_gender = 'F'
      AND wp.wp_type = 'content'
      AND wp.wp_char_count > 2000
      AND wp.wp_char_count < 20000
      AND EXISTS (
          SELECT 1
          FROM tpcds.household_demographics hd
          JOIN tpcds.income_band ib
              ON hd.hd_income_band_sk = ib.ib_income_band_sk
          WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
            AND ib.ib_upper_bound >= 150000
            AND hd.hd_vehicle_count >= 2
      )
      AND c.c_customer_sk IN (
          SELECT wp_customer_sk FROM tpcds.web_page WHERE wp_type = 'content'
          EXCEPT
          SELECT wp_customer_sk FROM tpcds.web_page WHERE wp_char_count > 15000
      )
),
url_segment_counts AS (
    SELECT
        fc.c_customer_sk,
        fc.wp_web_page_sk,
        COUNT(*) AS segment_cnt
    FROM filtered_customers fc
    CROSS JOIN UNNEST(split(fc.wp_url, '/')) AS t (segment)
    GROUP BY fc.c_customer_sk, fc.wp_web_page_sk
),
hd_income AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
aggregated AS (
    SELECT
        fc.c_customer_id,
        fc.ca_city,
        hi.ib_income_band_sk,
        COUNT(DISTINCT fc.wp_web_page_sk) AS page_count,
        SUM(fc.wp_char_count) AS total_char_count,
        AVG(fc.wp_image_count) AS avg_image_count,
        MIN(fc.wp_char_count) AS min_char_count,
        MAX(fc.wp_char_count) AS max_char_count,
        SUM(usc.segment_cnt) AS total_url_segments
    FROM filtered_customers fc
    JOIN hd_income hi
        ON hi.hd_demo_sk = fc.c_current_hdemo_sk
    LEFT JOIN url_segment_counts usc
        ON usc.c_customer_sk = fc.c_customer_sk
        AND usc.wp_web_page_sk = fc.wp_web_page_sk
    GROUP BY fc.c_customer_id, fc.ca_city, hi.ib_income_band_sk
    HAVING COUNT(DISTINCT fc.wp_web_page_sk) >= 3
       AND SUM(fc.wp_char_count) > 5000
)
SELECT
    a.c_customer_id,
    a.ca_city,
    a.ib_income_band_sk,
    a.page_count,
    a.total_char_count,
    a.avg_image_count,
    a.min_char_count,
    a.max_char_count,
    a.total_url_segments,
    LAG(a.total_char_count) OVER (PARTITION BY a.ca_city ORDER BY a.total_char_count DESC) AS lag_total_char_count,
    SUM(a.total_char_count) OVER (PARTITION BY a.ca_city ORDER BY a.total_char_count DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_char
FROM aggregated a
ORDER BY a.total_char_count DESC
LIMIT 100
