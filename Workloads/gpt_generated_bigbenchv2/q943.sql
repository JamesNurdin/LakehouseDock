WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^\\]]+)]', 1) AS log_timestamp,
        regexp_extract(line, '\\"([A-Z]+) ', 1) AS http_method,
        regexp_extract(line, '\\"[A-Z]+ ([^ ]+) ', 1) AS request_path,
        regexp_extract(line, '\\"\\s+([0-9]{3})\\s+([0-9]+)', 1) AS status_code,
        regexp_extract(line, '\\"\\s+([0-9]{3})\\s+([0-9]+)', 2) AS response_bytes
    FROM web_logs
)
SELECT
    http_method,
    request_path,
    status_code,
    COUNT(*) AS request_count,
    SUM(CAST(response_bytes AS BIGINT)) AS total_bytes,
    AVG(CAST(response_bytes AS DOUBLE)) AS avg_bytes
FROM parsed_logs
WHERE http_method IS NOT NULL
  AND request_path IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY http_method, request_path, status_code
ORDER BY request_count DESC
LIMIT 10
