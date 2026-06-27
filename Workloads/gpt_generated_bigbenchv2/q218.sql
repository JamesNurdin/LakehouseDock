WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\"(\w+)\s', 1) AS method,
        regexp_extract(line, '\"\w+\s([^\s]+)\s', 1) AS url,
        regexp_extract(line, '\"\s(\d{3})\s', 1) AS status_code
    FROM web_logs
    WHERE line LIKE '%\"%'
)
SELECT
    method,
    url,
    status_code,
    count(*) AS request_count
FROM parsed_logs
WHERE method IS NOT NULL
  AND url IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, url, status_code
ORDER BY request_count DESC
LIMIT 10
