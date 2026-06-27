WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^\\S+', 0) AS ip_address,
        regexp_extract(line, '\\[(.*?)\\]', 1) AS timestamp,
        regexp_extract(line, '"(\\S+) (\\S+) (\\S+)"', 1) AS http_method,
        regexp_extract(line, '"(\\S+) (\\S+) (\\S+)"', 2) AS request_path,
        regexp_extract(line, '"(\\S+) (\\S+) (\\S+)"', 3) AS http_version,
        regexp_extract(line, '"\\S+ \\S+ \\S+" (\\d{3})', 1) AS status_code,
        regexp_extract(line, '"\\S+ \\S+ \\S+" \\d{3} (\\d+)', 1) AS response_size
    FROM web_logs
)
SELECT
    http_method,
    status_code,
    COUNT(*) AS request_count,
    SUM(try_cast(response_size AS BIGINT)) AS total_bytes
FROM parsed_logs
WHERE http_method IS NOT NULL
GROUP BY http_method, status_code
ORDER BY request_count DESC
LIMIT 10
