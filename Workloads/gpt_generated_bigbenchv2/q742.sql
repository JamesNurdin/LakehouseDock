WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4})', 1) AS log_date,
        regexp_extract(line, '"([A-Z]+)\\s', 1) AS http_method,
        regexp_extract(line, '"\\s(\\d{3})\\s', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    log_date,
    http_method,
    status_code,
    COUNT(*) AS request_count,
    AVG(line_length) AS avg_line_length
FROM parsed_logs
WHERE log_date IS NOT NULL
  AND http_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY log_date, http_method, status_code
ORDER BY request_count DESC
LIMIT 20
