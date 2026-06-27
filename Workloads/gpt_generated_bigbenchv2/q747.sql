WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^\\s]+)', 1) AS ip,
        regexp_extract(line, '\\[(\\d{2}/\\w{3}/\\d{4}:\\d{2}:\\d{2}:\\d{2})', 1) AS timestamp_str,
        regexp_extract(line, '\\s"[A-Z]+\\s+([^\\s]+)\\s+HTTP/[^\\s]+"', 1) AS request_path,
        CAST(regexp_extract(line, '\\s(\\d{3})\\s', 1) AS integer) AS status_code_int
    FROM web_logs
)
SELECT
    ip,
    request_path,
    status_code_int,
    COUNT(*) AS request_count,
    MIN(timestamp_str) AS first_seen,
    MAX(timestamp_str) AS last_seen
FROM parsed_logs
WHERE ip IS NOT NULL
GROUP BY ip, request_path, status_code_int
ORDER BY request_count DESC
LIMIT 100
