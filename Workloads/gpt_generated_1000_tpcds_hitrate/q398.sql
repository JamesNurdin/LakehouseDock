SELECT d.d_date,
       COUNT(*) AS page_count,
       AVG(wp.wp_image_count) AS avg_image_count
FROM   web_page wp
JOIN   date_dim d
  ON   wp.wp_creation_date_sk = d.d_date_sk
WHERE  d.d_current_year = 'Y'
  AND  wp.wp_image_count > 3
GROUP BY d.d_date
ORDER BY d.d_date
