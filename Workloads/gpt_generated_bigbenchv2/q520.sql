WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^\"]+)"', 1) AS request_line,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code_str
    FROM web_logs
    WHERE line IS NOT NULL
),
request_parts AS (
    SELECT
        ip_address,
        timestamp_str,
        request_line,
        status_code_str,
        CAST(date_parse(timestamp_str, '%d/%b/%Y:%H:%i:%s %z') AS date) AS request_date,
        split(request_line, ' ')[1] AS http_method,
        split(request_line, ' ')[2] AS request_url,
        CAST(status_code_str AS integer) AS status_code
    FROM parsed_logs
    WHERE request_line IS NOT NULL
      AND status_code_str IS NOT NULL
)
SELECT
    request_date,
    http_method,
    status_code,
    COUNT(*) AS request_count,
    COUNT(DISTINCT ip_address) AS unique_ip_count
FROM request_parts
GROUP BY request_date, http_method, status_code
ORDER BY request_date DESC, request_count DESC
LIMIT 100
