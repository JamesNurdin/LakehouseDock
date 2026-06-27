WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '\\"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)\\s', 1) AS http_method,
        regexp_extract(line, '\\"\\s+(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\"(?:GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)\\s+([^\\s]+)', 1) AS url_path,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    url_path,
    http_method,
    status_code,
    count(*) AS request_count,
    avg(line_len) AS avg_line_length
FROM parsed_logs
WHERE url_path IS NOT NULL
  AND http_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY url_path, http_method, status_code
ORDER BY request_count DESC
LIMIT 20
