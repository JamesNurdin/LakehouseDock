WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^\\S+\\s+\\S+\\s+\\S+\\s+\\[[^\\]]+\\]\\s+"(\\S+)', 1) AS http_method,
        regexp_extract(line, '^\\S+\\s+\\S+\\s+\\S+\\s+\\[[^\\]]+\\]\\s+"[^"]+"\\s+(\\d{3})', 1) AS status_code,
        regexp_extract(line, '^\\S+\\s+\\S+\\s+\\S+\\s+\\[[^\\]]+\\]\\s+"[^"]+"\\s+\\d{3}\\s+(\\d+)', 1) AS size_bytes
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    http_method,
    status_code,
    count(*) AS request_count,
    sum(CAST(size_bytes AS BIGINT)) AS total_bytes,
    avg(CAST(size_bytes AS DOUBLE)) AS avg_bytes
FROM parsed_logs
WHERE http_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY http_method, status_code
ORDER BY request_count DESC
LIMIT 20
