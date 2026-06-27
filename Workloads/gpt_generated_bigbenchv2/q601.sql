WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[(.*?)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^ ]+) [^ ]+ HTTP/[^\"]+"', 1) AS http_method,
        regexp_extract(line, '"[^ ]+ ([^ ]+) HTTP/[^\"]+"', 1) AS request_path,
        CAST(regexp_extract(line, '"[^\"]+" ([0-9]{3})', 1) AS INTEGER) AS status_code,
        TRY_CAST(regexp_extract(line, '"[^\"]+" [0-9]{3} ([0-9]+)', 1) AS BIGINT) AS response_bytes
    FROM web_logs
)
SELECT
    http_method,
    status_code,
    COUNT(*) AS request_count,
    SUM(response_bytes) AS total_bytes
FROM parsed_logs
WHERE status_code IS NOT NULL
GROUP BY http_method, status_code
ORDER BY request_count DESC
LIMIT 10
