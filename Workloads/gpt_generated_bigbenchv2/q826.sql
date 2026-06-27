WITH parsed_logs AS (
  SELECT
    regexp_extract(line, '"([A-Z]+) ', 1)               AS method,
    regexp_extract(line, '"[A-Z]+\s+([^\s]+)', 1)      AS endpoint,
    CAST(regexp_extract(line, '\s(\d{3})\s', 1) AS INTEGER) AS status_code
  FROM web_logs
  WHERE line IS NOT NULL
)
SELECT
  method,
  status_code,
  COUNT(*)                         AS request_count,
  APPROX_DISTINCT(endpoint)        AS unique_endpoints
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
  AND status_code >= 400
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 20
