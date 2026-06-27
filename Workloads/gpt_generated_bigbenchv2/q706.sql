WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\"(\S+)\s', 1)               AS request_method,
        regexp_extract(line, '\"\S+\s(\S+)\s', 1)         AS request_path,
        regexp_extract(line, '\"\s+(\d{3})\s+', 1)        AS status_code,
        try_cast(regexp_extract(line, '\s(\d+)$', 1) AS bigint) AS response_size
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_method,
    request_path,
    status_code,
    COUNT(*)                         AS request_count,
    AVG(response_size)               AS avg_response_size,
    MIN(response_size)               AS min_response_size,
    MAX(response_size)               AS max_response_size
FROM parsed_logs
WHERE status_code IS NOT NULL
GROUP BY request_method, request_path, status_code
ORDER BY request_count DESC
LIMIT 20
