SELECT wp1.w_web_page_type,
       COUNT(*) AS pair_count
FROM web_pages wp1
JOIN web_pages wp2
  ON wp1.w_web_page_type = wp2.w_web_page_type
 AND wp1.w_web_page_id < wp2.w_web_page_id
GROUP BY wp1.w_web_page_type
ORDER BY pair_count DESC
