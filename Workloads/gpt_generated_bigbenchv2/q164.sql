WITH parsed_logs AS (
    SELECT
        line,
        length(line) AS line_length,
        CASE
            WHEN line LIKE '%error%' THEN 'error'
            WHEN line LIKE '%warning%' THEN 'warning'
            ELSE 'other'
        END AS log_type
    FROM web_logs
)
SELECT
    log_type,
    COUNT(*) AS log_count,
    AVG(line_length) AS avg_line_length,
    MIN(line_length) AS min_line_length,
    MAX(line_length) AS max_line_length,
    MIN(line) AS sample_line
FROM parsed_logs
GROUP BY log_type
ORDER BY log_count DESC
LIMIT 10
