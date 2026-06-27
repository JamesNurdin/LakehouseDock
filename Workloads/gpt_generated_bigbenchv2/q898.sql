SELECT
    w_web_page_type,
    count(*) AS page_count,
    avg(length(w_web_page_name)) AS avg_name_len,
    max(length(w_web_page_name)) AS max_name_len,
    max_by(w_web_page_name, length(w_web_page_name)) AS longest_page_name,
    approx_percentile(length(w_web_page_name), 0.5) AS median_name_len
FROM web_pages
WHERE w_web_page_type IS NOT NULL
GROUP BY w_web_page_type
HAVING count(*) >= 10
ORDER BY page_count DESC
