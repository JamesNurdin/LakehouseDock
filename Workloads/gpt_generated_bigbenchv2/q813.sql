WITH filtered_pages AS (
    SELECT w_web_page_id,
           w_web_page_name,
           w_web_page_type
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
),
type_aggregates AS (
    SELECT w_web_page_type,
           COUNT(*) AS page_count,
           COUNT(DISTINCT w_web_page_name) AS distinct_name_count,
           AVG(LENGTH(w_web_page_name)) AS avg_name_length
    FROM filtered_pages
    GROUP BY w_web_page_type
)
SELECT w_web_page_type,
       page_count,
       distinct_name_count,
       avg_name_length,
       RANK() OVER (ORDER BY page_count DESC) AS type_rank
FROM type_aggregates
ORDER BY page_count DESC
