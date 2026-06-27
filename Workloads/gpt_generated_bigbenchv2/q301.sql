WITH parsed_logs AS (
    SELECT
        line,
        CAST(regexp_extract(line, '\\"\\s+(\\d{3})\\s', 1) AS integer) AS status_code,
        CAST(regexp_extract(line, '\\[(?:\\d{2}/[A-Za-z]{3}/\\d{4}):(\\d{2}):\\d{2}:\\d{2}', 1) AS integer) AS hour_of_day,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    status_code,
    hour_of_day,
    COUNT(*) AS request_count,
    AVG(line_len) AS avg_line_length
FROM parsed_logs
WHERE status_code IS NOT NULL
  AND hour_of_day IS NOT NULL
GROUP BY status_code, hour_of_day
ORDER BY request_count DESC
LIMIT 20
