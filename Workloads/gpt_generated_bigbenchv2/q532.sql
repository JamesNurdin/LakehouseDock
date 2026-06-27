WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^\\S+', 0) AS ip_address,
        regexp_extract(line, '\\[(.*?)\\]', 1) AS timestamp,
        regexp_extract(line, '"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)\\s+([^\"]+)\\s+HTTP/\\d\\.\\d"', 1) AS method,
        regexp_extract(line, '"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)\\s+([^\"]+)\\s+HTTP/\\d\\.\\d"', 2) AS request_path,
        regexp_extract(line, '\\s+(\\d{3})\\s+', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    AVG(line_length) AS avg_line_length
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 10
