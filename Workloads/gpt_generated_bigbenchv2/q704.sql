WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS method,
        regexp_extract(line, '\\[([^:]+)', 1) AS log_date,
        regexp_extract(line, '"([^\"]*)"', 1) AS request,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
)
SELECT
    method,
    COUNT(*) AS total_requests,
    COUNT(DISTINCT request) AS distinct_requests,
    COUNT_IF(status_code = '200') AS ok_responses,
    COUNT_IF(status_code = '404') AS not_found_responses,
    AVG(line_length) AS avg_line_length
FROM parsed_logs
WHERE method IS NOT NULL
GROUP BY method
ORDER BY total_requests DESC
LIMIT 10
