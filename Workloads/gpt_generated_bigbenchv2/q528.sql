/* Top HTTP methods by request count and line‑length statistics */
WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([A-Z]+)\s', 1) AS http_method,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    http_method,
    COUNT(*) AS request_count,
    AVG(line_len) AS avg_line_length,
    MIN(line_len) AS min_line_length,
    MAX(line_len) AS max_line_length
FROM parsed_logs
WHERE http_method IS NOT NULL
GROUP BY http_method
ORDER BY request_count DESC
LIMIT 10
