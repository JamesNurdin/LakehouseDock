WITH parsed_logs AS (
    SELECT
        line,
        -- Extract a timestamp string at the start of the line (e.g., "2023-07-01 12:34:56" or "2023-07-01T12:34:56Z")
        regexp_extract(line, '^(\\d{4}-\\d{2}-\\d{2}[ T]\\d{2}:\\d{2}:\\d{2})', 1) AS ts_str,
        -- Extract a log level token if present (INFO, WARN, ERROR, DEBUG)
        regexp_extract(line, '\\b(INFO|WARN|ERROR|DEBUG)\\b', 1) AS log_level,
        length(line) AS line_len
    FROM web_logs
),
enriched_logs AS (
    SELECT
        line,
        ts_str,
        log_level,
        line_len,
        try_cast(ts_str AS timestamp) AS ts
    FROM parsed_logs
)
SELECT
    log_level,
    date_trunc('hour', ts) AS hour,
    COUNT(*) AS log_count,
    AVG(line_len) AS avg_line_length,
    MIN(line_len) AS min_line_length,
    MAX(line_len) AS max_line_length
FROM enriched_logs
WHERE log_level IS NOT NULL
  AND ts IS NOT NULL
GROUP BY log_level, date_trunc('hour', ts)
ORDER BY log_count DESC
LIMIT 20
