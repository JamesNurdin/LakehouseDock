WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '"([^\"]+)"', 1) AS request,
        split_part(regexp_extract(line, '"([^\"]+)"', 1), ' ', 1) AS method,
        split_part(regexp_extract(line, '"([^\"]+)"', 1), ' ', 2) AS url,
        split_part(regexp_extract(line, '"([^\"]+)"', 1), ' ', 3) AS protocol,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\s(\\d+)$', 1) AS bytes_sent
    FROM web_logs
)
SELECT
    method,
    url,
    status_code,
    COUNT(*) AS request_count,
    AVG(CAST(bytes_sent AS BIGINT)) AS avg_bytes,
    MIN(CAST(bytes_sent AS BIGINT)) AS min_bytes,
    MAX(CAST(bytes_sent AS BIGINT)) AS max_bytes
FROM parsed_logs
WHERE status_code IS NOT NULL
GROUP BY method, url, status_code
ORDER BY request_count DESC
LIMIT 20
