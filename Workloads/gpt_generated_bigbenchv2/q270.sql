WITH parsed_logs AS (
    SELECT
        line,
        split_part(line, ' ', 1) AS token,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    token,
    count(*) AS token_count,
    avg(line_len) AS avg_line_length,
    min(line_len) AS min_line_length,
    max(line_len) AS max_line_length
FROM parsed_logs
GROUP BY token
ORDER BY token_count DESC
LIMIT 10
