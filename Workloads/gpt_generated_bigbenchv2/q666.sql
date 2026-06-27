WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\"(\\S+) ', 1) AS http_method,
        regexp_extract(line, '\\"\\S+ (\\S+) ', 1) AS request_path,
        regexp_extract(line, '\\"\\S+ \\S+ \\S+\\" (\\d{3})', 1) AS status_code,
        regexp_extract(line, '\\"\\S+ \\S+ \\S+\\" \\d{3} (\\d+|-)', 1) AS response_size_str
    FROM web_logs
)
SELECT
    http_method,
    status_code,
    count(*) AS request_count,
    sum(CAST(nullif(response_size_str, '-') AS BIGINT)) AS total_bytes,
    avg(CAST(nullif(response_size_str, '-') AS DOUBLE)) AS avg_bytes
FROM parsed_logs
WHERE http_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY http_method, status_code
ORDER BY request_count DESC
LIMIT 10
