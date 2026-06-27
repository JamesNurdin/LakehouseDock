/*
  Analytical query: summary of web page types with statistics on the length of the page name.
  - Counts pages per type
  - Computes average, max, and min name length per type
  - Returns the longest page name per type using max_by
*/
WITH name_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        length(w_web_page_name) AS name_len
    FROM web_pages
    WHERE w_web_page_type IS NOT NULL
)
SELECT
    w_web_page_type,
    COUNT(*) AS page_count,
    AVG(name_len) AS avg_name_length,
    MAX(name_len) AS max_name_length,
    MIN(name_len) AS min_name_length,
    max_by(w_web_page_name, name_len) AS longest_page_name
FROM name_lengths
GROUP BY w_web_page_type
ORDER BY page_count DESC
