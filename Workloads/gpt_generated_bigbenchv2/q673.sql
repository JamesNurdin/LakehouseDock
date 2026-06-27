WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '\[(.+?)\]', 1) AS timestamp_str,
        regexp_extract(line, '\]\s+"(\w+)', 1) AS request_method,
        regexp_extract(line, '\]\s+"\w+\s+([^\s]+)', 1) AS request_path,
        regexp_extract(line, '"\s+(\d{3})\s', 1) AS status_code
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_method,
    status_code,
    COUNT(*) AS request_count
FROM parsed_logs
WHERE request_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY request_method, status_code
ORDER BY request_count DESC
LIMIT 20
