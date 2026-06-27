/*
  Analytical query on the web_logs table.
  It extracts the first token of each log line (commonly a log level),
  computes various line‑length statistics per log level, and returns the
  most common log levels.
*/
WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS log_level,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    log_level,
    COUNT(*) AS total_entries,
    COUNT(DISTINCT line) AS distinct_entries,
    AVG(line_len) AS avg_line_length,
    MIN(line_len) AS min_line_length,
    MAX(line_len) AS max_line_length,
    approx_percentile(line_len, 0.5) AS median_line_length
FROM parsed_logs
WHERE log_level IS NOT NULL
GROUP BY log_level
ORDER BY total_entries DESC
LIMIT 10
