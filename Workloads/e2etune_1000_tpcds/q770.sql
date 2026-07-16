WITH wp_time AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_image_count,
           wp.wp_link_count,
           wp.wp_char_count,
           wp.wp_customer_sk,
           wp.wp_creation_date_sk,
           td.t_hour,
           td.t_am_pm,
           td.t_meal_time
    FROM web_page wp
    JOIN time_dim td
      ON wp.wp_creation_date_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND td.t_am_pm = 'AM'
),
addr_store AS (
    SELECT ca.ca_address_sk,
           ca.ca_state,
           ca.ca_zip,
           ca.ca_location_type,
           ca.ca_gmt_offset,
           s.s_store_id,
           s.s_state,
           s.s_city,
           s.s_store_name,
           s.s_closed_date_sk
    FROM customer_address ca
    JOIN store s
      ON ca.ca_state = s.s_state
     AND ca.ca_zip = s.s_zip
    WHERE ca.ca_location_type = 'condo'
      AND ca.ca_gmt_offset = -7.00
      AND s.s_closed_date_sk IS NULL
)
SELECT
    asb.s_state,
    asb.s_city,
    wt.t_hour,
    COUNT(DISTINCT wt.wp_web_page_sk) AS num_pages,
    SUM(wt.wp_image_count) AS total_images,
    AVG(wt.wp_char_count) AS avg_chars,
    RANK() OVER (PARTITION BY asb.s_state ORDER BY SUM(wt.wp_image_count) DESC) AS image_rank
FROM wp_time wt
JOIN addr_store asb
  ON wt.wp_customer_sk = asb.ca_address_sk
GROUP BY asb.s_state, asb.s_city, wt.t_hour
HAVING COUNT(*) >= 10
ORDER BY total_images DESC, asb.s_state, wt.t_hour
LIMIT 100
