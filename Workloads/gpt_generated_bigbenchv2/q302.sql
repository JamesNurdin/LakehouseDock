WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '\\"(\\w+)\\s', 1) AS http_method,
        regexp_extract(line, '\\"\\w+\\s([^\\s]+)\\s', 1) AS request_path,
        CAST(regexp_extract(line, '\\"\\s(\\d{3})\\s', 1) AS integer) AS status_code,
        CAST(regexp_extract(line, '\\"\\s\\d{3}\\s(\\d+)', 1) AS integer) AS response_bytes
    FROM web_logs
)
SELECT
    http_method,
    status_code,
    COUNT(*) AS request_count,
    AVG(response_bytes) AS avg_response_bytes,
    MIN(response_bytes) AS min_response_bytes,
    MAX(response_bytes) AS max_response_bytes
FROM parsed_logs
WHERE http_method IS NOT NULL
GROUP BY http_method, status_code
ORDER BY request_count DESC
LIMIT 20
