WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '"([A-Z]+) ', 1) AS request_method,
        regexp_extract(line, '"[A-Z]+ ([^ ]+)', 1) AS request_path,
        regexp_extract(line, '" (\d{3}) ', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
)
SELECT
    status_code,
    request_method,
    COUNT(*) AS request_count,
    AVG(line_length) AS avg_line_length,
    MIN(line_length) AS min_line_length,
    MAX(line_length) AS max_line_length
FROM parsed_logs
WHERE status_code IS NOT NULL
GROUP BY status_code, request_method
ORDER BY request_count DESC
LIMIT 100
