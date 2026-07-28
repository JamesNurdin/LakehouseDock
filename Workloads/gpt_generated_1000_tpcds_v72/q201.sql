SELECT wp_type,
       COUNT(*) AS page_count,
       AVG(wp_image_count) AS avg_image_count
FROM tpcds.web_page
WHERE wp_image_count >= 3
  AND wp_url LIKE 'http://www.foo.com%'
GROUP BY wp_type
ORDER BY page_count DESC
LIMIT 100
