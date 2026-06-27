SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(LENGTH(w_web_page_name)) AS avg_name_length,
    slice(array_agg(w_web_page_name ORDER BY LENGTH(w_web_page_name) DESC), 1, 5) AS top_5_longest_names
FROM web_pages
WHERE w_web_page_name IS NOT NULL
GROUP BY w_web_page_type
ORDER BY page_count DESC
