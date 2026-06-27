WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^\\S+', 0) AS client_ip,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '\\"(\\S+)\\s+(\\S+)\\s+(\\S+)\\"', 1) AS request_method,
        regexp_extract(line, '\\"(\\S+)\\s+(\\S+)\\s+(\\S+)\\"', 2) AS request_path,
        regexp_extract(line, '\\"(\\S+)\\s+(\\S+)\\s+(\\S+)\\"', 3) AS request_protocol,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\s(\\d+)$', 1) AS response_size
    FROM web_logs
)
SELECT
    request_method,
    request_path,
    status_code,
    COUNT(*) AS request_count,
    SUM(CAST(response_size AS bigint)) AS total_bytes
FROM parsed_logs
WHERE request_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY request_method, request_path, status_code
ORDER BY request_count DESC
LIMIT 20
