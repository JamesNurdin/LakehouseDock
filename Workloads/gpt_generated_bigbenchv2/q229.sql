WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '"([^\"]+)"', 1) AS request,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    ip_address,
    COUNT(*) AS request_count,
    approx_distinct(request) AS distinct_requests,
    MAX(line_len) AS max_line_len,
    MIN(line_len) AS min_line_len
FROM parsed_logs
WHERE ip_address IS NOT NULL
GROUP BY ip_address
ORDER BY request_count DESC
LIMIT 20
