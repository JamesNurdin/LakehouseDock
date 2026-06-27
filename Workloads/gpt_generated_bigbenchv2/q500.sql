WITH line_metrics AS (
    SELECT
        line,
        length(line) AS line_length,
        cardinality(split(line, '\\s+')) AS token_count,
        regexp_count(line, '(?i)error') AS error_occurrences
    FROM web_logs
)
SELECT
    token_count,
    error_occurrences,
    count(*) AS line_cnt,
    avg(line_length) AS avg_line_len,
    min(line_length) AS min_line_len,
    max(line_length) AS max_line_len
FROM line_metrics
GROUP BY token_count, error_occurrences
ORDER BY line_cnt DESC
LIMIT 10
