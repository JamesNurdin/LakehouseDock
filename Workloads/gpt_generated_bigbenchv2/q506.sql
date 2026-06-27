WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"(\\S+) (\\S+) (\\S+)"', 1) AS request_method,
        regexp_extract(line, '"\\S+ (\\S+) \\S+"', 1) AS request_path,
        CAST(regexp_extract(line, '"\\S+ \\S+ \\S+"\\s+(\\d{3})', 1) AS integer) AS status_code,
        CAST(regexp_extract(line, '\\s(\\d+)$', 1) AS integer) AS bytes_sent
    FROM web_logs
)
SELECT
    request_method,
    status_code,
    COUNT(*) AS request_count,
    SUM(bytes_sent) AS total_bytes,
    AVG(CAST(bytes_sent AS double)) AS avg_bytes
FROM parsed_logs
WHERE request_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY request_method, status_code
ORDER BY request_count DESC
LIMIT 10
