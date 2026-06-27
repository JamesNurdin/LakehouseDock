WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '(\\d+\\.\\d+\\.\\d+\\.\\d+)', 1) AS ip_address,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    ip_address,
    COUNT(*) AS request_count,
    AVG(line_len) AS avg_line_length,
    MIN(line_len) AS min_line_length,
    MAX(line_len) AS max_line_length
FROM parsed_logs
WHERE ip_address IS NOT NULL
GROUP BY ip_address
HAVING COUNT(*) > 10
ORDER BY request_count DESC
LIMIT 100
