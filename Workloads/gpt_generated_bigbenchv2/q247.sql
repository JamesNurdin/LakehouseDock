/*
  Analytical query on the raw web log lines.
  It extracts the HTTP method, request URL, status code and response size,
  then aggregates request counts and byte statistics per method‑status pair.
*/
WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"(\\S+) (\\S+) (\\S+)"', 1) AS method,
        regexp_extract(line, '"(\\S+) (\\S+) (\\S+)"', 2) AS url,
        CAST(regexp_extract(line, '"\\s+(\\d{3})\\s+(\\d+)', 1) AS INTEGER) AS status_code,
        CAST(regexp_extract(line, '"\\s+\\d{3}\\s+(\\d+)', 1) AS INTEGER) AS bytes
    FROM web_logs
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    AVG(bytes) AS avg_bytes,
    SUM(bytes) AS total_bytes
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 10
