/*
  Analytical query on web_logs: extract IP, HTTP method, and status code from each log line,
  aggregate request counts per IP‑method‑status combination, and compute ranking and
  percentage share per IP.
*/
WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([0-9]{1,3}(?:\\.[0-9]{1,3}){3})', 1) AS ip,
        regexp_extract(line, '\\s"([A-Z]+)\\s', 1)      AS method,
        regexp_extract(line, '\\s([0-9]{3})\\s', 1)       AS status_code
    FROM web_logs
),
agg_counts AS (
    SELECT
        ip,
        method,
        status_code,
        COUNT(*) AS request_count
    FROM parsed_logs
    WHERE ip IS NOT NULL
    GROUP BY ip, method, status_code
)
SELECT
    ip,
    method,
    status_code,
    request_count,
    ROW_NUMBER() OVER (PARTITION BY ip ORDER BY request_count DESC) AS method_rank_for_ip,
    request_count * 100.0 / SUM(request_count) OVER (PARTITION BY ip) AS pct_of_ip_total
FROM agg_counts
ORDER BY request_count DESC
LIMIT 20
