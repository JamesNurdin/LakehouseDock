SELECT
    substr(line, 1, 1) AS first_char,
    COUNT(*) AS log_count,
    AVG(length(line)) AS avg_length,
    MIN(line) AS example_line
FROM web_logs
GROUP BY substr(line, 1, 1)
ORDER BY log_count DESC
LIMIT 10
