WITH parsed_logs AS (
    SELECT
        line,
        length(line) AS line_len,
        regexp_extract(line, '(\\d{4}-\\d{2}-\\d{2})', 1) AS log_date
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    log_date,
    COUNT(*) AS total_logs,
    COUNT(DISTINCT line) AS unique_lines,
    AVG(line_len) AS avg_line_length,
    MAX(line_len) AS max_line_length,
    MIN(line_len) AS min_line_length
FROM parsed_logs
WHERE log_date IS NOT NULL
GROUP BY log_date
ORDER BY total_logs DESC
LIMIT 10
