WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '\\"(\\w+)\\s[^\\\"]+\\"\\s(\\d{3})', 1) AS method,
        regexp_extract(line, '\\"(\\w+)\\s[^\\\"]+\\"\\s(\\d{3})', 2) AS status_code
    FROM web_logs
    WHERE regexp_extract(line, '\\"(\\w+)\\s[^\\\"]+\\"\\s(\\d{3})', 1) IS NOT NULL
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total_requests
FROM parsed_logs
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 10
