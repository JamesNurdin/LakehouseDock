WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^(\\S+)', 1) AS ip_address,
        regexp_extract(line, '\\"(GET|POST|PUT|DELETE|HEAD|OPTIONS)\\s', 1) AS http_method,
        regexp_extract(line, '\\"\\s(\\d{3})\\s', 1) AS status_code,
        CAST(regexp_extract(line, '\\"\\s\\d{3}\\s(\\d+)', 1) AS BIGINT) AS response_bytes,
        date_parse(regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4})', 1), '%d/%b/%Y') AS request_date,
        CAST(regexp_extract(line, '\\[(?:\\d{2}/[A-Za-z]{3}/\\d{4}):(\\d{2}):', 1) AS INTEGER) AS request_hour
    FROM web_logs
    WHERE regexp_extract(line, '\\"(GET|POST|PUT|DELETE|HEAD|OPTIONS)\\s', 1) IS NOT NULL
)
SELECT
    request_date,
    request_hour,
    http_method,
    status_code,
    COUNT(*) AS request_cnt,
    COUNT(DISTINCT ip_address) AS unique_ips,
    AVG(response_bytes) AS avg_bytes,
    MAX(response_bytes) AS max_bytes,
    MIN(response_bytes) AS min_bytes
FROM parsed_logs
GROUP BY request_date, request_hour, http_method, status_code
HAVING COUNT(*) > 100
ORDER BY request_cnt DESC
LIMIT 100
