WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]*)', 1) AS client_ip,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^\"]*)"', 1) AS request,
        regexp_extract(line, '"[^\"]*"\\s+(\d{3})', 1) AS status_code,
        regexp_extract(line, '"[^\"]*"\\s+\d{3}\\s+(\d+|-)', 1) AS response_bytes
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    status_code,
    COUNT(*) AS request_count,
    COUNT(DISTINCT client_ip) AS unique_clients,
    SUM(CASE WHEN response_bytes = '-' THEN 0 ELSE CAST(response_bytes AS BIGINT) END) AS total_bytes
FROM parsed_logs
GROUP BY status_code
ORDER BY request_count DESC
LIMIT 10
