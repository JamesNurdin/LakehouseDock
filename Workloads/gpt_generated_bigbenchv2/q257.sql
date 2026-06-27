WITH parsed_logs AS (
  SELECT
    hour(date_parse(regexp_extract(line, '\\[([^\\]]+)\\]', 1), '%d/%b/%Y:%H:%i:%s %z')) AS hour_of_day,
    regexp_extract(line, '"\\s(\\d{3})\\s', 1)                     AS status_code,
    regexp_extract(line, '"[A-Z]+\\s([^\\s]+)\\s', 1)               AS request_path
  FROM web_logs
)
SELECT
  hour_of_day,
  status_code,
  request_path,
  COUNT(*) AS request_count
FROM parsed_logs
WHERE hour_of_day IS NOT NULL
  AND status_code IS NOT NULL
  AND request_path IS NOT NULL
GROUP BY hour_of_day, status_code, request_path
ORDER BY request_count DESC
LIMIT 20
