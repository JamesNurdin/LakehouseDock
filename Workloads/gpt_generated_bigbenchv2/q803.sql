WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^\\S+ \\S+ \\S+ \\[[^\\]]+\\] "(\\S+)', 1) AS method,
        regexp_extract(line, '^\\S+ \\S+ \\S+ \\[[^\\]]+\\] "\\S+ (\\S+)', 1) AS path,
        CAST(regexp_extract(line, '\\s(\\d{3})\\s+\\d+$', 1) AS integer) AS status
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status,
    count(*) AS request_count,
    approx_distinct(path) AS distinct_paths
FROM parsed_logs
WHERE method IS NOT NULL
  AND status IS NOT NULL
GROUP BY method, status
ORDER BY request_count DESC
LIMIT 10
