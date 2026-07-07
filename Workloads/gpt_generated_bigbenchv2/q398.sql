WITH type_counts AS (
    SELECT w_web_page_type, COUNT(*) AS page_cnt
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT wp.w_web_page_id,
       wp.w_web_page_name,
       wp.w_web_page_type,
       tc.page_cnt
FROM web_pages wp
JOIN type_counts tc
  ON wp.w_web_page_type = tc.w_web_page_type
ORDER BY tc.page_cnt DESC, wp.w_web_page_id
