SELECT
    regexp_extract(line, '"(\w+) ', 1) AS request_method,
    regexp_extract(line, '" (\d{3}) ', 1) AS status_code,
    count(*) AS request_count
FROM web_logs
WHERE line IS NOT NULL
GROUP BY
    regexp_extract(line, '"(\w+) ', 1),
    regexp_extract(line, '" (\d{3}) ', 1)
ORDER BY request_count DESC
LIMIT 20
