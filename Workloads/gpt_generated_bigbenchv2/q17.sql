WITH raw_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp,
        regexp_extract(line, '"([^\"]*)"', 1) AS request,
        regexp_extract(line, '"[^\"]*"\\s+(\\d{3})', 1) AS status_code,
        regexp_extract(line, '"[^\"]*"\\s+\\d{3}\\s+(\\d+)', 1) AS response_size
    FROM web_logs
),
parsed_logs AS (
    SELECT
        line,
        ip_address,
        timestamp,
        request,
        status_code,
        response_size,
        regexp_extract(request, '^([^ ]+)', 1) AS http_method,
        regexp_extract(request, '^([^ ]+)\\s+([^ ]+)', 2) AS url_path
    FROM raw_logs
)
SELECT
    http_method,
    COUNT(*) AS request_count,
    COUNT(DISTINCT ip_address) AS unique_ip_count,
    AVG(CAST(response_size AS DOUBLE)) AS avg_response_bytes,
    SUM(CAST(response_size AS BIGINT)) AS total_response_bytes
FROM parsed_logs
WHERE http_method IS NOT NULL
GROUP BY http_method
ORDER BY request_count DESC
