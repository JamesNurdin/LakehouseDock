SELECT wp_web_page_id, wp_url, wp_char_count, wp_link_count
FROM tpcds.web_page
WHERE wp_char_count > 5000
  AND wp_link_count <= 10
ORDER BY wp_char_count DESC
LIMIT 10
