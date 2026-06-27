WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^\\s]+)', 1) AS ip,
        regexp_extract(line, '"([A-Z]+)\\s', 1) AS method,
        regexp_extract(line, '"\\s(\\d{3})\\s', 1) AS status_code,
        TRY_CAST(regexp_extract(line, '"\\s\\d{3}\\s(\\d+)', 1) AS BIGINT) AS response_size
    FROM web_logs
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    COUNT(DISTINCT ip) AS unique_ip_count,
    AVG(response_size) AS avg_response_size,
    approx_percentile(response_size, 0.5) AS median_response_size
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
  AND response_size IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 20
