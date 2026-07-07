WITH page_type_stats AS (
    SELECT w_web_page_type,
           COUNT(*) AS page_count,
           AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
    GROUP BY w_web_page_type
)
SELECT w_web_page_type,
       page_count,
       avg_name_length,
       RANK() OVER (ORDER BY page_count DESC) AS type_rank
FROM page_type_stats
ORDER BY page_count DESC
LIMIT 5
