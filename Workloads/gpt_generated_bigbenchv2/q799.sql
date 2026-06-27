WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([A-Z]+)\\s', 1) AS http_method,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    http_method,
    status_code,
    count(*) AS request_count,
    avg(line_length) AS avg_line_length
FROM parsed_logs
GROUP BY http_method, status_code
ORDER BY request_count DESC
