WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([A-Z]+)', 1) AS method,
        regexp_extract(line, '"\s(\d{3})\s', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
),
aggregated AS (
    SELECT
        method,
        status_code,
        COUNT(*) AS log_count,
        AVG(line_length) AS avg_line_length
    FROM parsed_logs
    WHERE method IS NOT NULL
    GROUP BY method, status_code
)
SELECT
    method,
    status_code,
    log_count,
    avg_line_length,
    SUM(log_count) OVER (ORDER BY log_count DESC) AS cumulative_log_count
FROM aggregated
ORDER BY log_count DESC
LIMIT 100
