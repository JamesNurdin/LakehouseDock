WITH type_counts AS (
    SELECT w_web_page_type,
           COUNT(*) AS page_type_count
    FROM web_pages
    GROUP BY w_web_page_type
),
total_count AS (
    SELECT COUNT(*) AS total_pages
    FROM web_pages
)
SELECT wp.w_web_page_id,
       wp.w_web_page_name,
       wp.w_web_page_type,
       tc.page_type_count,
       (tc.page_type_count * 100.0 / tot.total_pages) AS page_type_percentage
FROM web_pages AS wp
JOIN type_counts AS tc
  ON wp.w_web_page_type = tc.w_web_page_type
CROSS JOIN total_count AS tot
ORDER BY tc.page_type_count DESC, wp.w_web_page_id
