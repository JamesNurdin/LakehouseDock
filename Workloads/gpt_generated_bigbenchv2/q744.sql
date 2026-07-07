WITH page_type_counts AS (
    SELECT w_web_page_type AS page_type,
           COUNT(*) AS page_cnt
    FROM web_pages
    GROUP BY w_web_page_type
)
SELECT wp.w_web_page_type,
       ptc.page_cnt,
       COUNT(DISTINCT wp.w_web_page_name) AS distinct_name_cnt,
       AVG(LENGTH(wp.w_web_page_name)) AS avg_name_len
FROM web_pages wp
JOIN page_type_counts ptc
  ON wp.w_web_page_type = ptc.page_type
GROUP BY wp.w_web_page_type, ptc.page_cnt
ORDER BY ptc.page_cnt DESC
LIMIT 5
