WITH parsed AS (
    SELECT
        line,
        regexp_extract(line, '^([0-9]{1,3}(?:\.[0-9]{1,3}){3})', 1) AS ip_address,
        regexp_extract(line, '(\d{4}-\d{2}-\d{2})', 1) AS log_date,
        regexp_extract(line, '\s(\d{2}):\d{2}:\d{2}\s', 1) AS log_hour,
        regexp_extract(line, '\s(\d{3})\s', 1) AS status_code
    FROM web_logs
)
SELECT
    log_date,
    log_hour,
    status_code,
    COUNT(*) AS total_requests,
    COUNT(DISTINCT ip_address) AS unique_ip_count
FROM parsed
WHERE log_date IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY log_date, log_hour, status_code
ORDER BY total_requests DESC
LIMIT 100
