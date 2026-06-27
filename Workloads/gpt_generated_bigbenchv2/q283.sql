WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp_str,
        date_parse(regexp_extract(line, '\\[([^]]+)\\]', 1), '%d/%b/%Y:%H:%i:%s %z') AS ts,
        regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 1) AS request_method,
        regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 2) AS request_path,
        CAST(regexp_extract(line, '\\s(\\d{3})\\s', 1) AS INTEGER) AS status_code,
        CAST(regexp_extract(line, '\\s(\\d+)$', 1) AS BIGINT) AS response_size
    FROM web_logs
)
SELECT
    request_method,
    status_code,
    hour(ts) AS request_hour,
    COUNT(*) AS request_count,
    SUM(response_size) AS total_bytes,
    AVG(response_size) AS avg_bytes
FROM parsed_logs
WHERE request_method IS NOT NULL
  AND response_size IS NOT NULL
  AND ts IS NOT NULL
GROUP BY request_method, status_code, hour(ts)
ORDER BY request_count DESC
LIMIT 100
