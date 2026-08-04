SELECT
    wp_type,
    COUNT(*) AS page_count,
    AVG(wp_char_count) AS avg_char_count
FROM tpcds.web_page
WHERE wp_link_count > 10
  AND wp_image_count <= 3
GROUP BY wp_type
HAVING COUNT(*) >= 5
ORDER BY page_count DESC
