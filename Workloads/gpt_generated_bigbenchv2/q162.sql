WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '"([^\"]+)"', 1) AS request,
        regexp_extract(line, '"[^\"]+"\\s+(\\d{3})\\s+\d+', 1) AS status,
        regexp_extract(line, '"[^\"]+"\\s+\d{3}\\s+(\\d+)', 1) AS size
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    ip,
    request,
    status,
    COUNT(*) AS request_count,
    SUM(TRY_CAST(size AS BIGINT)) AS total_bytes
FROM parsed_logs
WHERE status IS NOT NULL
GROUP BY ip, request, status
ORDER BY request_count DESC
LIMIT 10
