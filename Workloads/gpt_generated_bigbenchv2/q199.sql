WITH parsed_logs AS (
    SELECT
        line,
        split_part(line, ' ', 1) AS first_token,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    first_token,
    AVG(line_len) AS avg_line_length,
    COUNT(*) AS log_count
FROM parsed_logs
GROUP BY first_token
ORDER BY log_count DESC
LIMIT 10
