WITH ip_logs AS (
    SELECT
        regexp_extract(line, '^(\\d+\\.\\d+\\.\\d+\\.\\d+)', 1) AS ip_address
    FROM web_logs
    WHERE regexp_extract(line, '^(\\d+\\.\\d+\\.\\d+\\.\\d+)', 1) IS NOT NULL
)
SELECT
    ip_address,
    COUNT(*) AS request_count
FROM ip_logs
GROUP BY ip_address
ORDER BY request_count DESC
LIMIT 10
