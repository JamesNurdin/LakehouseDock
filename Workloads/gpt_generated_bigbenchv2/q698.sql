WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\b\\d{3}\\b') AS status_code,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    status_code,
    COUNT(*) AS request_cnt,
    AVG(line_len) AS avg_line_len,
    MIN(line_len) AS min_line_len,
    MAX(line_len) AS max_line_len
FROM parsed_logs
WHERE status_code IS NOT NULL
GROUP BY status_code
ORDER BY request_cnt DESC
LIMIT 10
