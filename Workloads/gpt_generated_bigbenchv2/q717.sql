WITH page_data AS (
    SELECT w_web_page_id,
           w_web_page_name,
           w_web_page_type
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT page_data.w_web_page_type,
       COUNT(*) AS page_count,
       COUNT(DISTINCT page_data.w_web_page_name) AS distinct_name_count
FROM page_data
GROUP BY page_data.w_web_page_type
ORDER BY 2 DESC
