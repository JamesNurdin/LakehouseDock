WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"([A-Z]+)\\s', 1) AS method,
        regexp_extract(line, '"[A-Z]+\\s([^\\s]+)', 1) AS endpoint,
        regexp_extract(line, '"\\s+(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\s(\\d+)$', 1) AS bytes_sent
    FROM web_logs
)
SELECT
    method,
    endpoint,
    status_code,
    COUNT(*) AS request_count,
    SUM(TRY_CAST(bytes_sent AS BIGINT)) AS total_bytes
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, endpoint, status_code
ORDER BY request_count DESC
LIMIT 10
