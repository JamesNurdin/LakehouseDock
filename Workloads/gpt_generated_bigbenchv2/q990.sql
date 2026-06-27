WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"(\w+) ', 1) AS request_method,
        regexp_extract(line, '" (\d{3}) ', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_method,
    status_code,
    COUNT(*) AS request_count,
    AVG(line_length) AS avg_line_length
FROM parsed_logs
WHERE request_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY request_method, status_code
ORDER BY request_count DESC
LIMIT 100
