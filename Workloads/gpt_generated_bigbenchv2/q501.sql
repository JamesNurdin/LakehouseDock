WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '"([^"]+)"', 1) AS request,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\s(\\d+)$', 1) AS bytes_sent
    FROM web_logs
)
SELECT
    ip_address,
    COUNT(*) AS request_count,
    COUNT_IF(status_code = '200') AS ok_requests,
    COUNT_IF(status_code = '404') AS not_found_requests,
    SUM(CAST(bytes_sent AS BIGINT)) AS total_bytes
FROM parsed_logs
GROUP BY ip_address
ORDER BY request_count DESC
LIMIT 10
