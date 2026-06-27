WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH) ', 1) AS request_method,
        CAST(regexp_extract(line, '" (\d{3}) ', 1) AS INTEGER) AS status_code,
        CAST(regexp_extract(line, '" \d{3} (\d+)', 1) AS BIGINT) AS response_size
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_method,
    status_code,
    COUNT(*) AS request_count,
    AVG(response_size) AS avg_response_size,
    approx_percentile(response_size, 0.95) AS p95_response_size
FROM parsed_logs
WHERE request_method IS NOT NULL
GROUP BY request_method, status_code
ORDER BY request_count DESC
LIMIT 100
