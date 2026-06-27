WITH line_info AS (
    SELECT
        line,
        substr(line, 1, 1) AS first_char,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    first_char,
    COUNT(*) AS line_count,
    AVG(line_len) AS avg_len,
    MIN(line_len) AS min_len,
    MAX(line_len) AS max_len
FROM line_info
GROUP BY first_char
ORDER BY line_count DESC
LIMIT 10
