WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp_str,
        date(date_parse(regexp_extract(line, '\\[([^]]+)\\]', 1), 'dd/MMM/yyyy:HH:mm:ss Z')) AS request_date,
        regexp_extract(line, '"([A-Z]+) ', 1) AS request_method,
        regexp_extract(line, '"[A-Z]+ ([^ ]+) ', 1) AS request_url,
        regexp_extract(line, '"[^\"]*" ([0-9]{3})', 1) AS status_code,
        TRY_CAST(regexp_extract(line, '"[^\"]*" [0-9]{3} ([0-9]+)', 1) AS BIGINT) AS response_bytes
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_date,
    request_method,
    status_code,
    COUNT(*) AS request_count,
    AVG(response_bytes) AS avg_response_bytes,
    MIN(response_bytes) AS min_response_bytes,
    MAX(response_bytes) AS max_response_bytes
FROM parsed_logs
WHERE request_method IS NOT NULL
GROUP BY request_date, request_method, status_code
ORDER BY request_count DESC
LIMIT 20
