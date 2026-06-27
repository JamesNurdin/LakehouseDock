WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^.*?"([^ ]+) ', 1) AS method,
        regexp_extract(line, '^.*?"[^ ]+ ([^ ]+) ', 1) AS path,
        regexp_extract(line, '^.*?"[^\"]+" +([0-9]{3}) +', 1) AS status_code,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status_code,
    count(*) AS request_count,
    avg(line_len) AS avg_line_length
FROM parsed_logs
WHERE method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY method, status_code
ORDER BY request_count DESC
LIMIT 20
