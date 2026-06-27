WITH parsed_logs AS (
    SELECT
        line,
        element_at(split(line, ' '), 1) AS first_word,
        length(line) AS line_len,
        CASE WHEN lower(line) LIKE '%error%' THEN 1 ELSE 0 END AS is_error,
        cardinality(split(line, ' ')) AS token_count
    FROM web_logs
)
SELECT
    first_word,
    COUNT(*) AS total_logs,
    SUM(is_error) AS error_logs,
    AVG(line_len) AS avg_line_length,
    MIN(line_len) AS min_line_length,
    MAX(line_len) AS max_line_length,
    AVG(token_count) AS avg_token_count
FROM parsed_logs
GROUP BY first_word
ORDER BY total_logs DESC
LIMIT 20
