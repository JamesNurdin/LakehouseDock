WITH creation_dates AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_image_count,
        wp.wp_link_count,
        wp.wp_max_ad_count,
        wp.wp_creation_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM web_page wp
    JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = (
            SELECT MAX(d_year)
            FROM date_dim
            WHERE d_holiday = 'N'
          )
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND wp.wp_max_ad_count <= 2
      AND wp.wp_url LIKE 'http://www.%'
      AND EXISTS (
            SELECT 1
            FROM date_dim d2
            WHERE d2.d_date_sk = wp.wp_access_date_sk
              AND d2.d_weekend = 'Y'
          )
)
SELECT
    d_year,
    d_month_seq,
    COUNT(DISTINCT wp_web_page_sk) AS page_cnt,
    SUM(wp_char_count) AS total_chars,
    AVG(wp_image_count) AS avg_images,
    MAX(wp_link_count) AS max_links
FROM creation_dates
GROUP BY d_year, d_month_seq
ORDER BY d_year DESC, d_month_seq
