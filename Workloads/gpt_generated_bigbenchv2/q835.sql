/*
  Analytical query on the raw web log lines.
  - Extracts a log level (e.g., INFO, ERROR) from a leading "[LEVEL]" tag.
  - Extracts the hour component of a timestamp (YYYY‑MM‑DD HH) if present.
  - Extracts the first IPv4 address found in the line.
  - Computes the line length.
  Then aggregates per log level and hour, returning the count of logs,
  the average line length, and the number of distinct IP addresses.
*/
WITH extracted AS (
    SELECT
        line,
        regexp_extract(line, '^\[([^\]]+)\]', 1) AS log_level,
        regexp_extract(line, '(\d{4}-\d{2}-\d{2} \d{2}):\d{2}:\d{2}', 1) AS log_hour,
        regexp_extract(line, '(\d+\.\d+\.\d+\.\d+)', 1) AS ip_address,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    log_level,
    log_hour,
    count(*) AS log_count,
    avg(line_len) AS avg_line_length,
    count(DISTINCT ip_address) AS distinct_ip_count
FROM extracted
WHERE log_level IS NOT NULL
GROUP BY log_level, log_hour
ORDER BY log_count DESC
LIMIT 20
