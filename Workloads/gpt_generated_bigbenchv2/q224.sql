WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '"(\S+)\s', 1)        AS method,
        regexp_extract(line, '"[^\"]+"\s(\d{3})', 1) AS status_code,
        regexp_extract(line, '"\S+\s([^\s]+)', 1)   AS request_path
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status_code,
    request_path,
    count(*) AS request_count
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
  AND request_path IS NOT NULL
GROUP BY method, status_code, request_path
ORDER BY request_count DESC
LIMIT 10
