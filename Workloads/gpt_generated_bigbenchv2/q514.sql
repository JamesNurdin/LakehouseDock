WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4}:\\d{2}:\\d{2}:\\d{2})', 1) AS datetime_str,
        date_parse(
            regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4}:\\d{2}:\\d{2}:\\d{2})', 1),
            '%d/%b/%Y:%H:%i:%s'
        ) AS log_timestamp,
        regexp_extract(line, '\\"([A-Z]+) ', 1) AS request_method,
        regexp_extract(line, '\\"[A-Z]+ ([^ ]+)', 1) AS request_path,
        CAST(regexp_extract(line, '\\"[A-Z]+ [^ ]+ HTTP/[0-9\\.]+\\" (\\d{3})', 1) AS integer) AS status_code,
        CAST(regexp_extract(line, '\\"[A-Z]+ [^ ]+ HTTP/[0-9\\.]+\\" \\d{3} (\\d+)', 1) AS integer) AS response_bytes
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    date_trunc('hour', log_timestamp) AS hour,
    request_method,
    status_code,
    COUNT(*) AS request_count,
    SUM(response_bytes) AS total_bytes,
    AVG(response_bytes) AS avg_bytes
FROM parsed_logs
WHERE log_timestamp IS NOT NULL
GROUP BY
    date_trunc('hour', log_timestamp),
    request_method,
    status_code
ORDER BY
    date_trunc('hour', log_timestamp) DESC,
    request_count DESC
