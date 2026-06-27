WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^\"]*)"', 1) AS request,
        regexp_extract(line, '"[^\"]*"\\s+(\\d{3})', 1) AS status_code,
        regexp_extract(line, '"[^\"]*"\\s+\\d{3}\\s+(\\d+)', 1) AS bytes_sent,
        CAST(date_parse(regexp_extract(line, '\\[([^\\]]+)\\]', 1), '%d/%b/%Y:%H:%i:%s %z') AS DATE) AS log_date
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    log_date,
    COUNT(*) AS total_requests,
    COUNT(DISTINCT ip_address) AS unique_ips,
    SUM(TRY_CAST(bytes_sent AS BIGINT)) AS total_bytes,
    COUNT(*) FILTER (WHERE status_code = '200') AS ok_responses,
    COUNT(*) FILTER (WHERE status_code = '404') AS not_found_responses,
    AVG(TRY_CAST(bytes_sent AS DOUBLE)) AS avg_bytes_per_request
FROM parsed_logs
WHERE ip_address IS NOT NULL
  AND log_date IS NOT NULL
GROUP BY log_date
ORDER BY log_date DESC
LIMIT 30
