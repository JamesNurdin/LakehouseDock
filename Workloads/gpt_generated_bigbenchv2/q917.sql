WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS method,
        regexp_extract(line, '^([^ ]+) ([^ ]+)', 2) AS path,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
      AND line LIKE '%HTTP%'
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    AVG(line_length) AS avg_line_length,
    MIN(line_length) AS min_line_length,
    MAX(line_length) AS max_line_length
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 20
