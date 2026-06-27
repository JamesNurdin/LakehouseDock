WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS ts_str,
        date_parse(regexp_extract(line, '\\[([^\\]]+)\\]', 1), '%d/%b/%Y:%H:%i:%s %z') AS ts,
        hour(date_parse(regexp_extract(line, '\\[([^\\]]+)\\]', 1), '%d/%b/%Y:%H:%i:%s %z')) AS hour_of_day,
        regexp_extract(line, '"(\\w+) ', 1) AS request_method,
        regexp_extract(line, '"\\w+ ([^ ]+) ', 1) AS request_path,
        regexp_extract(line, '"\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '"\\s\\d{3}\\s(\\d+)', 1) AS response_size
    FROM web_logs
)
SELECT
    hour_of_day,
    status_code,
    COUNT(*) AS request_count,
    SUM(try_cast(response_size AS BIGINT)) AS total_bytes
FROM parsed_logs
GROUP BY hour_of_day, status_code
ORDER BY hour_of_day, status_code
