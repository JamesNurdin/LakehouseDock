WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([A-Z]+)', 1) AS method,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    count(*) AS request_count,
    avg(line_len) AS avg_line_length,
    max(line_len) AS max_line_length
FROM parsed_logs
WHERE method IS NOT NULL
GROUP BY method
ORDER BY request_count DESC
LIMIT 10
