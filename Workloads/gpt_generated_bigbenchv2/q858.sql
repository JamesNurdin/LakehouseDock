WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '"([^\"]+)"', 1) AS request,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status,
        regexp_extract(line, '\\s(\\d+)$', 1) AS size_str
    FROM web_logs
),
extracted_logs AS (
    SELECT
        ip,
        timestamp,
        request,
        status,
        TRY_CAST(size_str AS BIGINT) AS size,
        regexp_extract(request, '^([^ ]+)', 1) AS method,
        split(request, ' ')[2] AS endpoint
    FROM parsed_logs
    WHERE request IS NOT NULL
)
SELECT
    method,
    status,
    COUNT(*) AS request_count,
    SUM(size) AS total_bytes,
    APPROX_DISTINCT(ip) AS distinct_ip_count
FROM extracted_logs
WHERE status IS NOT NULL
GROUP BY method, status
ORDER BY request_count DESC
LIMIT 10
