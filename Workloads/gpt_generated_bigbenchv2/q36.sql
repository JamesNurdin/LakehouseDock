WITH type_counts AS (
    SELECT w_web_page_type,
           COUNT(*) AS page_count
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT w.w_web_page_id,
       w.w_web_page_name,
       w.w_web_page_type,
       tc.page_count
FROM web_pages w
JOIN type_counts tc
  ON w.w_web_page_type = tc.w_web_page_type
WHERE tc.page_count > 5
ORDER BY tc.page_count DESC
LIMIT 20
