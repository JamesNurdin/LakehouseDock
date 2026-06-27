/*
  Analyze the web log lines (Apache‑style) by extracting the HTTP method,
  the response status code, and the hour of the request. The query then
  aggregates the number of requests for each combination of method, hour,
  and status code, ordering the result by the highest request count.
*/
WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([A-Z]+)', 1)               AS method,
        regexp_extract(line, '\\s(\\d{3})\\s', 1)      AS status_code,
        regexp_extract(line, '\\[(?:\\d{2})/(?:\\w{3})/(?:\\d{4}):([0-9]{2}):', 1) AS hour
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    hour,
    status_code,
    COUNT(*) AS request_count
FROM parsed_logs
WHERE method IS NOT NULL
GROUP BY method, hour, status_code
ORDER BY request_count DESC
LIMIT 100
