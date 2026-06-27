WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '"([^"]*)"', 1) AS request,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\s(\\d+)$', 1) AS response_size
    FROM web_logs
)
SELECT
    status_code,
    COUNT(*) AS request_count,
    COUNT(DISTINCT ip_address) AS unique_ips,
    SUM(CAST(response_size AS BIGINT)) AS total_bytes
FROM parsed_logs
WHERE status_code IS NOT NULL
GROUP BY status_code
ORDER BY request_count DESC
LIMIT 10
