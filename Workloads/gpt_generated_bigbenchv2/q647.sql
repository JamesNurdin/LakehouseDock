WITH parsed AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[(.*?)\\]', 1) AS datetime_str,
        date_parse(regexp_extract(line, '\\[(.*?)\\]', 1), '%d/%b/%Y:%H:%i:%s %z') AS log_ts,
        regexp_extract(line, '"(?:GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH) ([^ ]+) HTTP/[^\"]+"', 1) AS request_path,
        regexp_extract(line, '"(?:GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH) [^ ]+ HTTP/[^\"]+" (\\d{3})', 1) AS status_code,
        regexp_extract(line, '"(?:GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH) [^ ]+ HTTP/[^\"]+" \\d{3} (\\d+|-)', 1) AS response_size_raw
    FROM web_logs
)
SELECT
    hour(log_ts) AS hour_of_day,
    status_code,
    COUNT(*) AS request_count,
    SUM(CASE WHEN response_size_raw = '-' THEN 0 ELSE CAST(response_size_raw AS BIGINT) END) AS total_bytes,
    AVG(CASE WHEN response_size_raw = '-' THEN NULL ELSE CAST(response_size_raw AS DOUBLE) END) AS avg_bytes
FROM parsed
WHERE status_code IS NOT NULL
GROUP BY hour(log_ts), status_code
ORDER BY hour_of_day, request_count DESC
