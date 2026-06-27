WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS log_timestamp,
        regexp_extract(line, '"([A-Z]+)\\s', 1) AS http_method,
        regexp_extract(line, '"[A-Z]+\\s([^\"]+)\\s', 1) AS request_path,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\s(\\d+)$', 1) AS response_bytes
    FROM web_logs
)
SELECT
    ip_address,
    http_method,
    COUNT(*) AS hit_count,
    COUNT(DISTINCT request_path) AS distinct_paths,
    SUM(CAST(response_bytes AS BIGINT)) AS total_bytes,
    MIN(log_timestamp) AS first_seen,
    MAX(log_timestamp) AS last_seen
FROM parsed_logs
WHERE http_method IS NOT NULL
GROUP BY ip_address, http_method
ORDER BY hit_count DESC
LIMIT 20
