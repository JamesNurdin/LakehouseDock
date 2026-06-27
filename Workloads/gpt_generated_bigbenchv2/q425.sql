WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\[([^:]+):', 1)                     AS request_date,
        regexp_extract(line, '\\"([A-Z]+) ', 1)                    AS http_method,
        regexp_extract(line, '\\"[A-Z]+ ([^ ]+) ', 1)             AS request_path,
        CAST(regexp_extract(line, '\\] \\"[A-Z]+ [^ ]+ \\" ([0-9]{3})', 1) AS integer) AS status_code,
        CAST(regexp_extract(line, '\\s([0-9]+)$', 1) AS integer)   AS response_size
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_date,
    http_method,
    status_code,
    COUNT(*)                         AS request_count,
    AVG(response_size)               AS avg_response_size,
    SUM(response_size)               AS total_response_size
FROM parsed_logs
GROUP BY
    request_date,
    http_method,
    status_code
ORDER BY
    request_date,
    request_count DESC
