SELECT wp_type,
       COUNT(*) AS page_count
FROM tpcds.web_page
WHERE wp_rec_end_date = DATE '2000-09-02'
  AND wp_url LIKE 'http://www.%'
GROUP BY wp_type
ORDER BY page_count DESC
