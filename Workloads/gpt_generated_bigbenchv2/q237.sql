WITH page_counts AS (
    SELECT w_web_page_type,
           COUNT(*) AS page_type_count
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT wp.w_web_page_id,
       wp.w_web_page_name,
       wp.w_web_page_type,
       pc.page_type_count
FROM web_pages wp
JOIN page_counts pc
  ON wp.w_web_page_type = pc.w_web_page_type
ORDER BY pc.page_type_count DESC,
         wp.w_web_page_id
LIMIT 10
