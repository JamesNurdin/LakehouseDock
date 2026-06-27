WITH parsed_logs AS (
    SELECT
        line,
        length(line) AS line_len,
        cardinality(split(line, ' ')) AS token_cnt,
        element_at(split(line, ' '), 1) AS first_token
    FROM web_logs
)
SELECT
    first_token AS token,
    COUNT(*) AS log_count,
    MIN(line_len) AS min_length,
    MAX(line_len) AS max_length,
    AVG(line_len) AS avg_length,
    MIN(token_cnt) AS min_token_count,
    MAX(token_cnt) AS max_token_count,
    AVG(token_cnt) AS avg_token_count,
    approx_distinct(line) AS distinct_log_lines
FROM parsed_logs
GROUP BY first_token
ORDER BY log_count DESC
LIMIT 10
