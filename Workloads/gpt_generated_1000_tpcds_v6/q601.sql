SELECT
  wp.wp_url,
  wp.wp_char_count,
  d.d_date,
  d.d_fy_year
FROM web_page wp
JOIN date_dim d
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_fy_year = 1915
  AND wp.wp_char_count > 3000
ORDER BY wp.wp_char_count DESC
LIMIT 100
