WITH page_stats AS (
  SELECT
    wp.wp_type,
    cd.d_year AS creation_year,
    cd.d_month_seq AS creation_month,
    DATE_DIFF('day', cd.d_date, ad.d_date) AS days_to_access,
    wp.wp_char_count,
    wp.wp_image_count,
    wp.wp_link_count,
    ad.d_weekend AS access_weekend
  FROM web_page wp
  JOIN date_dim cd ON wp.wp_creation_date_sk = cd.d_date_sk
  JOIN date_dim ad ON wp.wp_access_date_sk = ad.d_date_sk
  WHERE cd.d_holiday = 'Y'
    AND wp.wp_type IS NOT NULL
),
aggregated AS (
  SELECT
    wp_type,
    creation_year,
    creation_month,
    COUNT(*) AS page_cnt,
    AVG(wp_char_count) AS avg_char_cnt,
    SUM(wp_image_count) AS total_image_cnt,
    AVG(days_to_access) AS avg_days_to_access,
    SUM(CASE WHEN access_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_access_cnt,
    CAST(SUM(CASE WHEN access_weekend = 'Y' THEN 1 ELSE 0 END) AS double) / COUNT(*) AS weekend_access_ratio
  FROM page_stats
  GROUP BY wp_type, creation_year, creation_month
  HAVING COUNT(*) >= 10
)
SELECT
  wp_type,
  creation_year,
  creation_month,
  page_cnt,
  avg_char_cnt,
  total_image_cnt,
  avg_days_to_access,
  weekend_access_cnt,
  weekend_access_ratio,
  RANK() OVER (PARTITION BY creation_year ORDER BY avg_char_cnt DESC) AS char_cnt_rank
FROM aggregated
ORDER BY creation_year DESC, creation_month, page_cnt DESC
LIMIT 100
