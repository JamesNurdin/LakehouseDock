WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^\"]+)"', 1) AS request_line,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
)
SELECT
    ip,
    status_code,
    COUNT(*) AS request_cnt,
    AVG(line_length) AS avg_line_len,
    MIN(timestamp_str) AS earliest_ts,
    MAX(timestamp_str) AS latest_ts
FROM parsed_logs
WHERE ip IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY ip, status_code
ORDER BY request_cnt DESC
LIMIT 10
