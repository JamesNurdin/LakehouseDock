WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[(.*?)\\]', 1) AS timestamp,
        regexp_extract(line, '\\"(\\S+)\\s', 1) AS method,
        regexp_extract(line, '\\"\\S+\\s(\\S+)\\s', 1) AS url,
        regexp_extract(line, '\\"\\s(\\d{3})\\s', 1) AS status,
        regexp_extract(line, '\\"\\s\\d{3}\\s(\\d+)', 1) AS size
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status,
    count(*) AS request_count,
    avg(CAST(size AS BIGINT)) AS avg_response_size
FROM parsed_logs
WHERE method IS NOT NULL
  AND status IS NOT NULL
  AND size IS NOT NULL
GROUP BY method, status
ORDER BY request_count DESC
LIMIT 10
