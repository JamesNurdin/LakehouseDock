WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\d{4}-\\d{2}-\\d{2}') AS log_date,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    log_date,
    count(*) AS cnt,
    avg(line_len) AS avg_len
FROM parsed_logs
WHERE log_date IS NOT NULL
GROUP BY log_date
ORDER BY cnt DESC
LIMIT 20
