WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '"(\\w+)\\s', 1) AS method,
        regexp_extract(line, '"\\s(\\d{3})\\s', 1) AS status_code,
        CAST(regexp_extract(line, '"\\s\\d{3}\\s(\\d+)', 1) AS BIGINT) AS response_size
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    AVG(response_size) AS avg_response_size,
    SUM(response_size) AS total_response_bytes
FROM parsed_logs
WHERE method IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 20
