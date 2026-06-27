WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^\\S+ \\S+ \\S+ \\[[^]]*\\] "(\\S+) ', 1) AS method,
        regexp_extract(line, '^\\S+ \\S+ \\S+ \\[[^]]*\\] "\\S+ (\\S+) ', 1) AS request_path,
        regexp_extract(line, '^\\S+ \\S+ \\S+ \\[[^]]*\\] "\\S+ \\S+ \\S+" (\\d{3}) ', 1) AS status_code,
        TRY_CAST(regexp_extract(line, '^\\S+ \\S+ \\S+ \\[[^]]*\\] "\\S+ \\S+ \\S+" \\d{3} (\\d+)', 1) AS BIGINT) AS response_bytes
    FROM web_logs
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    AVG(response_bytes) AS avg_response_bytes,
    MIN(response_bytes) AS min_response_bytes,
    MAX(response_bytes) AS max_response_bytes
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 20
