WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"([A-Z]+) ', 1) AS http_method,
        regexp_extract(line, '"\s+(\d{3})\s+', 1) AS status_code_str,
        regexp_extract(line, '\\s+(\\d+)$', 1) AS response_size_str,
        regexp_extract(line, '\\[([^:]+):', 1) AS request_date_str
    FROM web_logs
),
typed_logs AS (
    SELECT
        line,
        http_method,
        CAST(status_code_str AS integer) AS status_code,
        CAST(response_size_str AS integer) AS response_size,
        CAST(date_parse(request_date_str, '%d/%b/%Y') AS date) AS request_date
    FROM parsed_logs
)
SELECT
    request_date,
    http_method,
    status_code,
    COUNT(*) AS request_count,
    AVG(response_size) AS avg_response_size,
    SUM(response_size) AS total_response_size
FROM typed_logs
GROUP BY request_date, http_method, status_code
ORDER BY request_date DESC, request_count DESC
